import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models.dart';

List<Position> getLegalMoves({
  required Position from,
  required Map<Position, Piece> board,
}) {
  final piece = board[from];
  if (piece == null) return const [];

  final maxDist = piece.definition.moveDistance;
  final moves = <Position>[];

  const directions = [
    (0, 1),   // North
    (0, -1),  // South
    (1, 0),   // East
    (-1, 0),  // West
    (1, 1),   // North-East
    (-1, 1),  // North-West
    (1, -1),  // South-East
    (-1, -1), // South-West
  ];

  for (final (dc, dr) in directions) {
    for (int step = 1; step <= maxDist; step++) {
      final nextCol = from.col + dc * step;
      final nextRow = from.row + dr * step;
      final nextPos = Position(nextCol, nextRow);

      if (!nextPos.isOnBoard) {
        break;
      }

      // No jumping over any piece (friend or enemy).
      // Cannot land on an occupied square.
      if (board.containsKey(nextPos)) {
        break;
      }

      // River rules:
      if (isRiverPosition(nextPos)) {
        if (piece.type == PieceType.phantom) {
          // Phantom may jump over a river square as part of its move,
          // but can never land on it.
          continue;
        } else {
          // Non-Phantom pieces cannot enter or skip the river.
          break;
        }
      }

      // Normal or Bridge square:
      moves.add(nextPos);
    }
  }

  return moves;
}

List<(int, int)> getAttackDirections(Piece piece) {
  switch (piece.definition.attackDirection) {
    case AttackDirection.front:
      return piece.side == PlayerSide.blue ? const [(0, 1)] : const [(0, -1)];
    case AttackDirection.frontDiagonal:
      final forward = piece.side == PlayerSide.blue ? (0, 1) : (0, -1);
      return [
        forward,
        (1, 1),
        (-1, 1),
        (1, -1),
        (-1, -1),
      ];
    case AttackDirection.all:
      return const [
        (0, 1),
        (0, -1),
        (1, 0),
        (-1, 0),
        (1, 1),
        (-1, 1),
        (1, -1),
        (-1, -1),
      ];
  }
}

List<Position> getAttackTargets({
  required Position from,
  required Map<Position, Piece> board,
}) {
  final attacker = board[from];
  if (attacker == null) return const [];
  // Dormant Phantom cannot attack
  if (attacker.type == PieceType.phantom && attacker.isDormant) return const [];

  final targets = <Position>[];
  final directions = getAttackDirections(attacker);
  final range = attacker.definition.range;

  for (final (dc, dr) in directions) {
    for (int step = 1; step <= range; step++) {
      final nextPos = Position(from.col + dc * step, from.row + dr * step);
      if (!nextPos.isOnBoard) break;

      final pieceAtSquare = board[nextPos];
      if (pieceAtSquare != null) {
        // First piece found is the only candidate
        if (pieceAtSquare.side != attacker.side) {
          // If attacker is Healer (poison action), target must not already be poisoned
          if (attacker.type == PieceType.healer) {
            if (!pieceAtSquare.isPoisoned) {
              targets.add(nextPos);
            }
          } else {
            targets.add(nextPos);
          }
        }
        // Blocked by first piece (friend or enemy)
        break;
      }
      // River and bridge squares do NOT block attacks
    }
  }

  return targets;
}

List<Position> getHealerHealTargets({
  required Position from,
  required Map<Position, Piece> board,
}) {
  final healer = board[from];
  if (healer == null || healer.type != PieceType.healer) return const [];

  final targets = <Position>[];
  const directions = [
    (0, 1),
    (0, -1),
    (1, 0),
    (-1, 0),
    (1, 1),
    (-1, 1),
    (1, -1),
    (-1, -1),
  ];
  final range = healer.definition.range; // 4

  for (final (dc, dr) in directions) {
    for (int step = 1; step <= range; step++) {
      final nextPos = Position(from.col + dc * step, from.row + dr * step);
      if (!nextPos.isOnBoard) break;

      final pieceAtSquare = board[nextPos];
      if (pieceAtSquare != null) {
        if (pieceAtSquare.side == healer.side && nextPos != from) {
          final isDamaged = pieceAtSquare.currentHp < pieceAtSquare.definition.hp;
          final isPoisoned = pieceAtSquare.isPoisoned;
          if (isDamaged || isPoisoned) {
            targets.add(nextPos);
          }
        }
        // Line of sight is IGNORED for healing; pieces in between do not block
      }
    }
  }

  return targets;
}

Position? findPiecePosition({
  required PlayerSide side,
  required PieceType type,
  required Map<Position, Piece> board,
}) {
  for (final entry in board.entries) {
    if (entry.value.side == side && entry.value.type == type) {
      return entry.key;
    }
  }
  return null;
}

List<Position> getSummonDestinations({
  required PlayerSide side,
  required Map<Position, Piece> board,
}) {
  final crownPos = findPiecePosition(side: side, type: PieceType.crown, board: board);
  final phantomPos = findPiecePosition(side: side, type: PieceType.phantom, board: board);
  if (crownPos == null || phantomPos == null) return const [];

  const directions = [
    (0, 1),
    (0, -1),
    (1, 0),
    (-1, 0),
    (1, 1),
    (-1, 1),
    (1, -1),
    (-1, -1),
  ];

  final destinations = <Position>[];
  for (final (dc, dr) in directions) {
    final nextPos = Position(crownPos.col + dc, crownPos.row + dr);
    if (nextPos.isOnBoard && !board.containsKey(nextPos) && !isRiverPosition(nextPos)) {
      destinations.add(nextPos);
    }
  }

  return destinations;
}

bool canPlayerSummon({
  required PlayerSide side,
  required bool summonUsed,
  required Map<Position, Piece> board,
}) {
  if (summonUsed) return false;
  return getSummonDestinations(side: side, board: board).isNotEmpty;
}

void applyAttackDamage({
  required Piece attacker,
  required Piece defender,
}) {
  if (attacker.type == PieceType.mage) {
    // Mage attack is Burn: damage = atk (2) goes straight to hp and ignores armor
    defender.currentHp -= attacker.definition.atk;
  } else {
    // Normal attack: armor absorbs first; remaining damage hits hp
    final damage = attacker.definition.atk;
    if (defender.currentArmor >= damage) {
      defender.currentArmor -= damage;
    } else {
      final excess = damage - defender.currentArmor;
      defender.currentArmor = 0;
      defender.currentHp -= excess;
    }
  }
}

Map<Position, Piece> createInitialBoard() {
  final board = <Position, Piece>{};

  // Blue Row 2 (cols a-k)
  final blueRow2 = [
    PieceType.knight, // a2
    PieceType.knight, // b2
    PieceType.tank,   // c2
    PieceType.knight, // d2
    PieceType.knight, // e2
    PieceType.tank,   // f2
    PieceType.knight, // g2
    PieceType.knight, // h2
    PieceType.tank,   // i2
    PieceType.knight, // j2
    PieceType.knight, // k2
  ];

  for (int col = 0; col < blueRow2.length; col++) {
    final type = blueRow2[col];
    final pos = Position(col, 2);
    board[pos] = Piece(
      id: 'blue_${type.name}_${pos.notation}',
      type: type,
      side: PlayerSide.blue,
    );
  }

  // Blue Row 1 (cols a-k)
  final blueRow1 = [
    PieceType.phantom, // a1 (fixed)
    PieceType.crown,   // b1
    PieceType.healer,  // c1
    PieceType.healer,  // d1
    PieceType.archer,  // e1
    PieceType.archer,  // f1
    PieceType.mage,    // g1
    PieceType.mage,    // h1
    PieceType.tank,    // i1
    PieceType.archer,  // j1
    PieceType.scepter, // k1 (fixed)
  ];

  for (int col = 0; col < blueRow1.length; col++) {
    final type = blueRow1[col];
    final pos = Position(col, 1);
    board[pos] = Piece(
      id: 'blue_${type.name}_${pos.notation}',
      type: type,
      side: PlayerSide.blue,
    );
  }

  // Red is Blue rotated 180 degrees (col -> 10 - col, row -> 14 - row)
  final blueEntries = board.entries.toList();
  for (final entry in blueEntries) {
    final bluePos = entry.key;
    final bluePiece = entry.value;

    final redCol = (boardCols - 1) - bluePos.col;
    final redRow = (boardRows + 1) - bluePos.row;
    final redPos = Position(redCol, redRow);

    board[redPos] = Piece(
      id: 'red_${bluePiece.type.name}_${redPos.notation}',
      type: bluePiece.type,
      side: PlayerSide.red,
    );
  }

  return board;
}

class GameState extends ChangeNotifier {
  Map<Position, Piece> _board = {};
  PlayerSide _currentTurn = PlayerSide.blue;
  PlayerSide? _winner;
  Position? _selectedPosition;
  List<Position> _legalMoves = const [];
  List<Position> _attackTargets = const [];
  List<Position> _healTargets = const [];

  bool _blueSummonUsed = false;
  bool _redSummonUsed = false;
  bool _isSummoning = false;
  List<Position> _summonDestinations = const [];

  GameState() {
    reset();
  }

  Map<Position, Piece> get board => _board;
  PlayerSide get currentTurn => _currentTurn;
  PlayerSide? get winner => _winner;
  bool get isGameOver => _winner != null;
  Position? get selectedPosition => _selectedPosition;
  Piece? get selectedPiece => _selectedPosition != null ? _board[_selectedPosition] : null;
  List<Position> get legalMoves => _legalMoves;
  List<Position> get attackTargets => _attackTargets;
  List<Position> get healTargets => _healTargets;

  bool get blueSummonUsed => _blueSummonUsed;
  bool get redSummonUsed => _redSummonUsed;
  bool get isSummoning => _isSummoning;
  List<Position> get summonDestinations => _summonDestinations;

  bool get canCurrentPlayerSummon =>
      !isGameOver &&
      canPlayerSummon(
        side: _currentTurn,
        summonUsed: _currentTurn == PlayerSide.blue ? _blueSummonUsed : _redSummonUsed,
        board: _board,
      );

  void reset() {
    _board = createInitialBoard();
    _currentTurn = PlayerSide.blue;
    _winner = null;
    _blueSummonUsed = false;
    _redSummonUsed = false;
    _isSummoning = false;
    _selectedPosition = null;
    _legalMoves = const [];
    _attackTargets = const [];
    _healTargets = const [];
    _summonDestinations = const [];
    notifyListeners();
  }

  void toggleSummon() {
    if (isGameOver) return;
    if (_isSummoning) {
      _isSummoning = false;
      _summonDestinations = const [];
      notifyListeners();
      return;
    }

    if (!canCurrentPlayerSummon) return;

    _isSummoning = true;
    _summonDestinations = getSummonDestinations(side: _currentTurn, board: _board);
    _selectedPosition = null;
    _legalMoves = const [];
    _attackTargets = const [];
    _healTargets = const [];
    notifyListeners();
  }

  void handleCellTap(Position pos) {
    if (isGameOver) return;

    if (_isSummoning) {
      if (_summonDestinations.contains(pos)) {
        executeSummon(pos);
        return;
      }
      // Tap outside cancels summon mode
      _isSummoning = false;
      _summonDestinations = const [];
    }

    if (_selectedPosition != null) {
      // Tap a heal target
      if (_healTargets.contains(pos)) {
        healPiece(_selectedPosition!, pos);
        return;
      }

      // Tap an attack target
      if (_attackTargets.contains(pos)) {
        attackPiece(_selectedPosition!, pos);
        return;
      }

      // Tap a legal move square
      if (_legalMoves.contains(pos)) {
        movePiece(_selectedPosition!, pos);
        return;
      }
    }

    // Tapping ANY piece (either side) selects it
    if (_board.containsKey(pos)) {
      selectPiece(pos);
      return;
    }

    // Tapped an empty square that is not a legal move
    deselect();
  }

  void selectPiece(Position pos) {
    final piece = _board[pos];
    if (piece == null) return;

    _isSummoning = false;
    _summonDestinations = const [];
    _selectedPosition = pos;

    if (piece.side == _currentTurn && !isGameOver) {
      _legalMoves = getLegalMoves(from: pos, board: _board);
      _attackTargets = getAttackTargets(from: pos, board: _board);
      _healTargets = getHealerHealTargets(from: pos, board: _board);
    } else {
      _legalMoves = const [];
      _attackTargets = const [];
      _healTargets = const [];
    }

    notifyListeners();
  }

  void deselect() {
    if (_selectedPosition != null ||
        _legalMoves.isNotEmpty ||
        _attackTargets.isNotEmpty ||
        _healTargets.isNotEmpty ||
        _isSummoning) {
      _selectedPosition = null;
      _legalMoves = const [];
      _attackTargets = const [];
      _healTargets = const [];
      _isSummoning = false;
      _summonDestinations = const [];
      notifyListeners();
    }
  }

  void movePiece(Position from, Position to) {
    if (isGameOver) return;
    final piece = _board[from];
    if (piece == null || piece.side != _currentTurn) return;
    if (!_legalMoves.contains(to)) return;

    _board[to] = piece;
    _board.remove(from);

    _endTurn();
  }

  void attackPiece(Position attackerPos, Position defenderPos) {
    if (isGameOver) return;
    final attacker = _board[attackerPos];
    final defender = _board[defenderPos];
    if (attacker == null || defender == null || attacker.side != _currentTurn) return;
    if (!_attackTargets.contains(defenderPos)) return;

    if (attacker.type == PieceType.healer) {
      // Healer poison action: -1 hp immediately (ignoring armor) and set poison turns = 2
      defender.currentHp -= 1;
      defender.poisonTurns = 2;
      if (defender.currentHp <= 0) {
        _board.remove(defenderPos);
        if (defender.type == PieceType.crown) {
          _winner = attacker.side;
        }
      }
    } else {
      applyAttackDamage(attacker: attacker, defender: defender);
      if (defender.currentHp <= 0) {
        _board.remove(defenderPos);
        if (defender.type == PieceType.crown) {
          _winner = attacker.side;
        }
      }
    }

    _endTurn();
  }

  void healPiece(Position healerPos, Position targetPos) {
    if (isGameOver) return;
    final healer = _board[healerPos];
    final target = _board[targetPos];
    if (healer == null || target == null || healer.side != _currentTurn) return;
    if (healer.type != PieceType.healer || !_healTargets.contains(targetPos)) return;

    // +1 hp (never above starting hp) and remove poison
    target.currentHp = min(target.definition.hp, target.currentHp + 1);
    target.poisonTurns = 0;

    _endTurn();
  }

  void executeSummon(Position destination) {
    if (isGameOver) return;
    if (!canCurrentPlayerSummon) return;
    if (!_summonDestinations.contains(destination)) return;

    final phantomPos = findPiecePosition(side: _currentTurn, type: PieceType.phantom, board: _board);
    if (phantomPos == null) return;

    final phantom = _board.remove(phantomPos)!;
    phantom.isDormant = true;
    _board[destination] = phantom;

    if (_currentTurn == PlayerSide.blue) {
      _blueSummonUsed = true;
    } else {
      _redSummonUsed = true;
    }

    _endTurn();
  }

  void _endTurn() {
    _selectedPosition = null;
    _legalMoves = const [];
    _attackTargets = const [];
    _healTargets = const [];
    _isSummoning = false;
    _summonDestinations = const [];

    // Poison tick: at the END of the poisoned piece's owner's turn
    final entries = _board.entries.toList();
    for (final entry in entries) {
      final pos = entry.key;
      final piece = entry.value;
      if (piece.side == _currentTurn && piece.isPoisoned) {
        piece.poisonTurns -= 1;
        if (piece.poisonTurns == 0) {
          piece.currentHp -= 1;
          if (piece.currentHp <= 0) {
            _board.remove(pos);
            if (piece.type == PieceType.crown) {
              _winner = (_currentTurn == PlayerSide.blue) ? PlayerSide.red : PlayerSide.blue;
            }
          }
        }
      }
    }

    if (_winner == null) {
      _currentTurn = (_currentTurn == PlayerSide.blue) ? PlayerSide.red : PlayerSide.blue;
      // Waking up dormant Phantoms on their owner's turn
      for (final piece in _board.values) {
        if (piece.side == _currentTurn && piece.type == PieceType.phantom) {
          piece.isDormant = false;
        }
      }
    }

    notifyListeners();
  }
}
