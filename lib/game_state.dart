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

Map<Position, Piece> createInitialDeploymentBoard() {
  final board = <Position, Piece>{};

  // Fixed starting squares
  board[Position.fromNotation('a1')] = Piece(
    id: 'blue_phantom_a1',
    type: PieceType.phantom,
    side: PlayerSide.blue,
  );
  board[Position.fromNotation('k1')] = Piece(
    id: 'blue_scepter_k1',
    type: PieceType.scepter,
    side: PlayerSide.blue,
  );
  board[Position.fromNotation('k13')] = Piece(
    id: 'red_phantom_k13',
    type: PieceType.phantom,
    side: PlayerSide.red,
  );
  board[Position.fromNotation('a13')] = Piece(
    id: 'red_scepter_a13',
    type: PieceType.scepter,
    side: PlayerSide.red,
  );

  return board;
}

Map<Position, PieceType> sampleDeploymentLayout(PlayerSide side) {
  if (side == PlayerSide.blue) {
    return {
      // Row 1 (b1-j1): Crown, Healer, Healer, Archer, Archer, Mage, Mage, Tank, Archer
      Position.fromNotation('b1'): PieceType.crown,
      Position.fromNotation('c1'): PieceType.healer,
      Position.fromNotation('d1'): PieceType.healer,
      Position.fromNotation('e1'): PieceType.archer,
      Position.fromNotation('f1'): PieceType.archer,
      Position.fromNotation('g1'): PieceType.mage,
      Position.fromNotation('h1'): PieceType.mage,
      Position.fromNotation('i1'): PieceType.tank,
      Position.fromNotation('j1'): PieceType.archer,
      // Row 2 (a2-k2): Knight, Knight, Tank, Knight, Knight, Tank, Knight, Knight, Tank, Knight, Knight
      Position.fromNotation('a2'): PieceType.knight,
      Position.fromNotation('b2'): PieceType.knight,
      Position.fromNotation('c2'): PieceType.tank,
      Position.fromNotation('d2'): PieceType.knight,
      Position.fromNotation('e2'): PieceType.knight,
      Position.fromNotation('f2'): PieceType.tank,
      Position.fromNotation('g2'): PieceType.knight,
      Position.fromNotation('h2'): PieceType.knight,
      Position.fromNotation('i2'): PieceType.tank,
      Position.fromNotation('j2'): PieceType.knight,
      Position.fromNotation('k2'): PieceType.knight,
    };
  } else {
    final blue = sampleDeploymentLayout(PlayerSide.blue);
    final red = <Position, PieceType>{};
    for (final entry in blue.entries) {
      final bPos = entry.key;
      final rPos = Position((boardCols - 1) - bPos.col, (boardRows + 1) - bPos.row);
      red[rPos] = entry.value;
    }
    return red;
  }
}

Map<Position, Piece> createInitialBoard() {
  final board = createInitialDeploymentBoard();
  for (final entry in sampleDeploymentLayout(PlayerSide.blue).entries) {
    board[entry.key] = Piece(
      id: 'blue_${entry.value.name}_${entry.key.notation}',
      type: entry.value,
      side: PlayerSide.blue,
    );
  }
  for (final entry in sampleDeploymentLayout(PlayerSide.red).entries) {
    board[entry.key] = Piece(
      id: 'red_${entry.value.name}_${entry.key.notation}',
      type: entry.value,
      side: PlayerSide.red,
    );
  }
  return board;
}

// Snapshot for undo
class _GameSnapshot {
  final Map<Position, Piece> board;
  final PlayerSide currentTurn;
  final PlayerSide? winner;
  final bool blueSummonUsed;
  final bool redSummonUsed;
  final int turnCounter;
  final List<String> log;

  _GameSnapshot({
    required this.board,
    required this.currentTurn,
    required this.winner,
    required this.blueSummonUsed,
    required this.redSummonUsed,
    required this.turnCounter,
    required this.log,
  });
}

class GameState extends ChangeNotifier {
  GamePhase _phase = GamePhase.blueDeployment;
  Map<Position, Piece> _board = {};
  PlayerSide _currentTurn = PlayerSide.blue;
  PlayerSide? _winner;
  Position? _selectedPosition;
  List<Position> _legalMoves = const [];
  List<Position> _attackTargets = const [];
  List<Position> _healTargets = const [];

  Map<PieceType, int> _blueRemainingPieces = initialDeploymentCounts();
  Map<PieceType, int> _redRemainingPieces = initialDeploymentCounts();
  PieceType? _selectedTrayPiece;

  bool _blueSummonUsed = false;
  bool _redSummonUsed = false;
  bool _isSummoning = false;
  List<Position> _summonDestinations = const [];

  int _turnCounter = 1;
  final List<String> _log = [];
  final List<_GameSnapshot> _undoStack = [];

  GameState({GamePhase initialPhase = GamePhase.blueDeployment}) {
    if (initialPhase == GamePhase.play) {
      startPlay();
    } else {
      reset();
    }
  }

  void startPlay() {
    _phase = GamePhase.play;
    _board = createInitialBoard();
    _blueRemainingPieces = {for (final k in initialDeploymentCounts().keys) k: 0};
    _redRemainingPieces = {for (final k in initialDeploymentCounts().keys) k: 0};
    _selectedTrayPiece = null;
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
    _turnCounter = 1;
    _log.clear();
    _undoStack.clear();
    notifyListeners();
  }

  // ── Log helpers ──────────────────────────────────────────────────────────
  void _addLog(String line) {
    _log.add(line);
    if (_log.length > 100) _log.removeAt(0);
  }

  List<String> get log => List.unmodifiable(_log);
  int get turnCounter => _turnCounter;
  bool get canUndo => _undoStack.isNotEmpty;

  // ── Snapshot helpers ─────────────────────────────────────────────────────
  _GameSnapshot _takeSnapshot() {
    final boardCopy = <Position, Piece>{};
    for (final entry in _board.entries) {
      final p = entry.value;
      boardCopy[entry.key] = Piece(
        id: p.id,
        type: p.type,
        side: p.side,
        currentHp: p.currentHp,
        currentArmor: p.currentArmor,
        poisonTurns: p.poisonTurns,
        isDormant: p.isDormant,
      );
    }
    return _GameSnapshot(
      board: boardCopy,
      currentTurn: _currentTurn,
      winner: _winner,
      blueSummonUsed: _blueSummonUsed,
      redSummonUsed: _redSummonUsed,
      turnCounter: _turnCounter,
      log: List.of(_log),
    );
  }

  void _saveSnapshot() => _undoStack.add(_takeSnapshot());

  void undo() {
    if (_undoStack.isEmpty) return;
    final snap = _undoStack.removeLast();
    _board = snap.board;
    _currentTurn = snap.currentTurn;
    _winner = snap.winner;
    _blueSummonUsed = snap.blueSummonUsed;
    _redSummonUsed = snap.redSummonUsed;
    _turnCounter = snap.turnCounter;
    _log
      ..clear()
      ..addAll(snap.log);
    _selectedPosition = null;
    _legalMoves = const [];
    _attackTargets = const [];
    _healTargets = const [];
    _isSummoning = false;
    _summonDestinations = const [];
    notifyListeners();
  }

  GamePhase get phase => _phase;
  bool get isDeployment => _phase == GamePhase.blueDeployment || _phase == GamePhase.redDeployment;
  PlayerSide get deploymentSide => (_phase == GamePhase.blueDeployment) ? PlayerSide.blue : PlayerSide.red;

  Map<PieceType, int> get blueRemainingPieces => Map.unmodifiable(_blueRemainingPieces);
  Map<PieceType, int> get redRemainingPieces => Map.unmodifiable(_redRemainingPieces);
  Map<PieceType, int> get currentRemainingPieces =>
      _phase == GamePhase.blueDeployment ? _blueRemainingPieces : _redRemainingPieces;
  PieceType? get selectedTrayPiece => _selectedTrayPiece;

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
      _phase == GamePhase.play &&
      !isGameOver &&
      canPlayerSummon(
        side: _currentTurn,
        summonUsed: _currentTurn == PlayerSide.blue ? _blueSummonUsed : _redSummonUsed,
        board: _board,
      );

  bool isPieceVisible(Position pos, Piece piece) {
    if (_phase == GamePhase.play) return true;
    if (_phase == GamePhase.blueDeployment) {
      return piece.side == PlayerSide.blue || isFixedStartingPosition(pos);
    }
    if (_phase == GamePhase.redDeployment) {
      return piece.side == PlayerSide.red || isFixedStartingPosition(pos);
    }
    return false;
  }

  void reset() {
    _phase = GamePhase.blueDeployment;
    _board = createInitialDeploymentBoard();
    _blueRemainingPieces = initialDeploymentCounts();
    _redRemainingPieces = initialDeploymentCounts();
    _selectedTrayPiece = null;

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
    _turnCounter = 1;
    _log.clear();
    _undoStack.clear();
    notifyListeners();
  }

  // Deployment Methods
  void selectTrayPiece(PieceType type) {
    if (!isDeployment) return;
    final counts = currentRemainingPieces;
    if ((counts[type] ?? 0) <= 0) return;

    if (_selectedTrayPiece == type) {
      _selectedTrayPiece = null;
    } else {
      _selectedTrayPiece = type;
    }
    notifyListeners();
  }

  bool placePiece(Position pos) {
    if (!isDeployment) return false;
    if (_selectedTrayPiece == null) return false;

    final side = deploymentSide;
    final counts = (side == PlayerSide.blue) ? _blueRemainingPieces : _redRemainingPieces;
    if ((counts[_selectedTrayPiece!] ?? 0) <= 0) return false;

    if (!isInDeploymentZone(side, pos)) return false;
    if (_board.containsKey(pos)) return false;

    _board[pos] = Piece(
      id: '${side.name}_${_selectedTrayPiece!.name}_${pos.notation}',
      type: _selectedTrayPiece!,
      side: side,
    );
    counts[_selectedTrayPiece!] = counts[_selectedTrayPiece!]! - 1;

    if (counts[_selectedTrayPiece!] == 0) {
      _selectedTrayPiece = null;
    }

    notifyListeners();
    return true;
  }

  bool removePiece(Position pos) {
    if (!isDeployment) return false;
    final side = deploymentSide;

    final piece = _board[pos];
    if (piece == null || piece.side != side) return false;
    if (isFixedStartingPosition(pos)) return false;

    _board.remove(pos);
    final counts = (side == PlayerSide.blue) ? _blueRemainingPieces : _redRemainingPieces;
    counts[piece.type] = (counts[piece.type] ?? 0) + 1;

    notifyListeners();
    return true;
  }

  void autoFill([PlayerSide? targetSide]) {
    final side = targetSide ?? deploymentSide;

    // Remove all non-fixed pieces of side
    _board.removeWhere((pos, piece) => piece.side == side && !isFixedStartingPosition(pos));

    // Place sample layout
    final layout = sampleDeploymentLayout(side);
    for (final entry in layout.entries) {
      _board[entry.key] = Piece(
        id: '${side.name}_${entry.value.name}_${entry.key.notation}',
        type: entry.value,
        side: side,
      );
    }

    // Set counts to 0
    final counts = (side == PlayerSide.blue) ? _blueRemainingPieces : _redRemainingPieces;
    for (final key in counts.keys) {
      counts[key] = 0;
    }

    _selectedTrayPiece = null;
    notifyListeners();
  }

  void clearDeployment([PlayerSide? targetSide]) {
    final side = targetSide ?? deploymentSide;

    _board.removeWhere((pos, piece) => piece.side == side && !isFixedStartingPosition(pos));

    final counts = (side == PlayerSide.blue) ? _blueRemainingPieces : _redRemainingPieces;
    final init = initialDeploymentCounts();
    for (final entry in init.entries) {
      counts[entry.key] = entry.value;
    }

    _selectedTrayPiece = null;
    notifyListeners();
  }

  bool canCompleteDeployment([PlayerSide? targetSide]) {
    final side = targetSide ?? deploymentSide;
    final counts = (side == PlayerSide.blue) ? _blueRemainingPieces : _redRemainingPieces;
    return counts.values.every((c) => c == 0);
  }

  void completeDeployment() {
    if (_phase == GamePhase.blueDeployment) {
      if (!canCompleteDeployment(PlayerSide.blue)) return;
      _phase = GamePhase.passToRed;
      _selectedTrayPiece = null;
      notifyListeners();
    } else if (_phase == GamePhase.redDeployment) {
      if (!canCompleteDeployment(PlayerSide.red)) return;
      _phase = GamePhase.passToBlue;
      _selectedTrayPiece = null;
      notifyListeners();
    }
  }

  void continueFromHandover() {
    if (_phase == GamePhase.passToRed) {
      _phase = GamePhase.redDeployment;
      _selectedTrayPiece = null;
      notifyListeners();
    } else if (_phase == GamePhase.passToBlue) {
      _phase = GamePhase.play;
      _currentTurn = PlayerSide.blue;
      _selectedTrayPiece = null;
      _turnCounter = 1;
      _log.clear();
      _undoStack.clear();
      notifyListeners();
    }
  }

  // Play Actions
  void toggleSummon() {
    if (_phase != GamePhase.play || isGameOver) return;
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
    if (isDeployment) {
      final currentSide = deploymentSide;

      if (_board.containsKey(pos)) {
        final piece = _board[pos]!;
        if (piece.side == currentSide && !isFixedStartingPosition(pos)) {
          removePiece(pos);
        }
        return;
      }

      if (_selectedTrayPiece != null && isInDeploymentZone(currentSide, pos)) {
        placePiece(pos);
      }
      return;
    }

    if (_phase != GamePhase.play || isGameOver) return;

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
    if (_phase != GamePhase.play) return;
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
    if (_phase != GamePhase.play || isGameOver) return;
    final piece = _board[from];
    if (piece == null || piece.side != _currentTurn) return;
    if (!_legalMoves.contains(to)) return;

    _saveSnapshot();
    _addLog('${piece.side.displayName} ${piece.definition.name} ${from.notation} -> ${to.notation}');

    _board[to] = piece;
    _board.remove(from);

    _endTurn();
  }

  void attackPiece(Position attackerPos, Position defenderPos) {
    if (_phase != GamePhase.play || isGameOver) return;
    final attacker = _board[attackerPos];
    final defender = _board[defenderPos];
    if (attacker == null || defender == null || attacker.side != _currentTurn) return;
    if (!_attackTargets.contains(defenderPos)) return;

    _saveSnapshot();

    if (attacker.type == PieceType.healer) {
      // Healer poison action: -1 hp immediately (ignoring armor) and set poison turns = 2
      _addLog('${attacker.side.displayName} ${attacker.definition.name} ${attackerPos.notation} poisons ${defender.side.displayName} ${defender.definition.name} ${defenderPos.notation} (-1 HP)');
      defender.currentHp -= 1;
      defender.poisonTurns = 2;
      if (defender.currentHp <= 0) {
        _board.remove(defenderPos);
        _addLog('${defender.side.displayName} ${defender.definition.name} ${defenderPos.notation} dies');
        if (defender.type == PieceType.crown) {
          _winner = attacker.side;
          _addLog('${attacker.side.displayName} wins: ${defender.side.displayName} Crown has fallen');
        }
      }
    } else {
      final isBurn = attacker.type == PieceType.mage;
      final verb = isBurn ? 'burns' : 'hits';
      final damage = attacker.definition.atk;
      // Determine what gets hit for log
      String damageDesc;
      if (isBurn) {
        damageDesc = '($damage to HP)';
      } else {
        if (defender.currentArmor >= damage) {
          damageDesc = '($damage to Armor)';
        } else {
          final armorAbsorbed = defender.currentArmor;
          final hpDamage = damage - armorAbsorbed;
          if (armorAbsorbed > 0) {
            damageDesc = '($hpDamage to HP)';
          } else {
            damageDesc = '($damage to HP)';
          }
        }
      }
      _addLog('${attacker.side.displayName} ${attacker.definition.name} ${attackerPos.notation} $verb ${defender.side.displayName} ${defender.definition.name} ${defenderPos.notation} $damageDesc');
      applyAttackDamage(attacker: attacker, defender: defender);
      if (defender.currentHp <= 0) {
        _board.remove(defenderPos);
        _addLog('${defender.side.displayName} ${defender.definition.name} ${defenderPos.notation} dies');
        if (defender.type == PieceType.crown) {
          _winner = attacker.side;
          _addLog('${attacker.side.displayName} wins: ${defender.side.displayName} Crown has fallen');
        }
      }
    }

    _endTurn();
  }

  void healPiece(Position healerPos, Position targetPos) {
    if (_phase != GamePhase.play || isGameOver) return;
    final healer = _board[healerPos];
    final target = _board[targetPos];
    if (healer == null || target == null || healer.side != _currentTurn) return;
    if (healer.type != PieceType.healer || !_healTargets.contains(targetPos)) return;

    _saveSnapshot();
    final wasPoisoned = target.isPoisoned;

    // +1 hp (never above starting hp) and remove poison
    target.currentHp = min(target.definition.hp, target.currentHp + 1);
    target.poisonTurns = 0;

    final curedStr = wasPoisoned ? ', cured' : '';
    _addLog('${healer.side.displayName} ${healer.definition.name} ${healerPos.notation} heals ${target.side.displayName} ${target.definition.name} ${targetPos.notation} (+1 HP$curedStr)');

    _endTurn();
  }

  void executeSummon(Position destination) {
    if (_phase != GamePhase.play || isGameOver) return;
    if (!canCurrentPlayerSummon) return;
    if (!_summonDestinations.contains(destination)) return;

    final phantomPos = findPiecePosition(side: _currentTurn, type: PieceType.phantom, board: _board);
    if (phantomPos == null) return;

    _saveSnapshot();
    _addLog('${_currentTurn.displayName} Crown summons Phantom to ${destination.notation}');

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
          _addLog('${piece.side.displayName} ${piece.definition.name} ${pos.notation} takes poison (-1 HP)');
          if (piece.currentHp <= 0) {
            _board.remove(pos);
            _addLog('${piece.side.displayName} ${piece.definition.name} ${pos.notation} dies');
            if (piece.type == PieceType.crown) {
              _winner = (_currentTurn == PlayerSide.blue) ? PlayerSide.red : PlayerSide.blue;
              _addLog('${_winner!.displayName} wins: ${_currentTurn.displayName} Crown has fallen');
            }
          }
        }
      }
    }

    _turnCounter += 1;

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
