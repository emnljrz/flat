import 'package:flutter_test/flutter_test.dart';
import 'package:flat/models.dart';
import 'package:flat/game_state.dart';

void main() {
  group('Initial Board Setup', () {
    test('places exactly 22 Blue and 22 Red pieces with fixed positions', () {
      final board = createInitialBoard();

      expect(board.length, equals(44));

      final bluePieces = board.values.where((p) => p.side == PlayerSide.blue).toList();
      final redPieces = board.values.where((p) => p.side == PlayerSide.red).toList();

      expect(bluePieces.length, equals(22));
      expect(redPieces.length, equals(22));

      // Fixed squares: Phantom a1/k13, Scepter k1/a13
      expect(board[Position.fromNotation('a1')]?.type, equals(PieceType.phantom));
      expect(board[Position.fromNotation('a1')]?.side, equals(PlayerSide.blue));

      expect(board[Position.fromNotation('k1')]?.type, equals(PieceType.scepter));
      expect(board[Position.fromNotation('k1')]?.side, equals(PlayerSide.blue));

      expect(board[Position.fromNotation('k13')]?.type, equals(PieceType.phantom));
      expect(board[Position.fromNotation('k13')]?.side, equals(PlayerSide.red));

      expect(board[Position.fromNotation('a13')]?.type, equals(PieceType.scepter));
      expect(board[Position.fromNotation('a13')]?.side, equals(PlayerSide.red));
    });
  });

  group('River and Phantom Movement Rules', () {
    test('non-phantom pieces cannot enter or skip river squares', () {
      final board = <Position, Piece>{
        Position.fromNotation('d6'): Piece(
          id: 'kn1',
          type: PieceType.knight, // Move distance 2
          side: PlayerSide.blue,
        ),
      };

      // d7 is a river square. Knight moving straight up:
      final moves = getLegalMoves(
        from: Position.fromNotation('d6'),
        board: board,
      );

      // d7 is river, so Knight cannot step on d7 or jump to d8
      expect(moves.contains(Position.fromNotation('d7')), isFalse);
      expect(moves.contains(Position.fromNotation('d8')), isFalse);
    });

    test('phantom jumps over river squares without landing on them', () {
      final board = <Position, Piece>{
        Position.fromNotation('d6'): Piece(
          id: 'phn1',
          type: PieceType.phantom, // Move distance 3
          side: PlayerSide.blue,
        ),
      };

      final moves = getLegalMoves(
        from: Position.fromNotation('d6'),
        board: board,
      );

      // d7 is river -> phantom cannot land on it
      expect(moves.contains(Position.fromNotation('d7')), isFalse);

      // phantom jumps over d7 -> can land on d8 (dist 2) and d9 (dist 3)
      expect(moves.contains(Position.fromNotation('d8')), isTrue);
      expect(moves.contains(Position.fromNotation('d9')), isTrue);
    });

    test('phantom can jump over river diagonally', () {
      final board = <Position, Piece>{
        Position.fromNotation('c6'): Piece(
          id: 'phn1',
          type: PieceType.phantom,
          side: PlayerSide.blue,
        ),
      };

      final moves = getLegalMoves(
        from: Position.fromNotation('c6'),
        board: board,
      );

      // (c6 + (1, 1)) = d7 (river). Phantom cannot land on d7, but reaches e8 and f9
      expect(moves.contains(Position.fromNotation('d7')), isFalse);
      expect(moves.contains(Position.fromNotation('e8')), isTrue);
      expect(moves.contains(Position.fromNotation('f9')), isTrue);
    });
  });

  group('Bridge Rules and Bridge Block', () {
    test('pieces can walk onto and through an open bridge', () {
      final board = <Position, Piece>{
        Position.fromNotation('e6'): Piece(
          id: 'kn1',
          type: PieceType.knight, // Move distance 2
          side: PlayerSide.blue,
        ),
      };

      final moves = getLegalMoves(
        from: Position.fromNotation('e6'),
        board: board,
      );

      // e7 is a bridge square. Knight can land on e7 and continue to e8.
      expect(moves.contains(Position.fromNotation('e7')), isTrue);
      expect(moves.contains(Position.fromNotation('e8')), isTrue);
    });

    test('piece on a bridge blocks passage through it', () {
      final board = <Position, Piece>{
        Position.fromNotation('e6'): Piece(
          id: 'kn1',
          type: PieceType.knight, // Move distance 2
          side: PlayerSide.blue,
        ),
        Position.fromNotation('e7'): Piece(
          id: 'blocker',
          type: PieceType.tank,
          side: PlayerSide.red,
        ),
      };

      final moves = getLegalMoves(
        from: Position.fromNotation('e6'),
        board: board,
      );

      // e7 is occupied, so Knight cannot land on e7 and cannot pass through to e8
      expect(moves.contains(Position.fromNotation('e7')), isFalse);
      expect(moves.contains(Position.fromNotation('e8')), isFalse);
    });

    test('phantom cannot jump over an occupied bridge square', () {
      final board = <Position, Piece>{
        Position.fromNotation('e6'): Piece(
          id: 'phn1',
          type: PieceType.phantom, // Move distance 3
          side: PlayerSide.blue,
        ),
        Position.fromNotation('e7'): Piece(
          id: 'blocker',
          type: PieceType.tank,
          side: PlayerSide.red,
        ),
      };

      final moves = getLegalMoves(
        from: Position.fromNotation('e6'),
        board: board,
      );

      // e7 is occupied by a piece -> blocked (no jumping over pieces)
      expect(moves.contains(Position.fromNotation('e7')), isFalse);
      expect(moves.contains(Position.fromNotation('e8')), isFalse);
      expect(moves.contains(Position.fromNotation('e9')), isFalse);
    });
  });

  group('Turn Alternation and Game Flow', () {
    test('turns alternate between Blue and Red on move', () {
      final gameState = GameState(initialPhase: GamePhase.play);

      expect(gameState.currentTurn, equals(PlayerSide.blue));

      // Attempt to select a Red piece during Blue's turn selects it for viewing only (no moves)
      gameState.handleCellTap(Position.fromNotation('a12'));
      expect(gameState.selectedPosition, equals(Position.fromNotation('a12')));
      expect(gameState.legalMoves, isEmpty);

      // Select a Blue knight at b2
      gameState.handleCellTap(Position.fromNotation('b2'));
      expect(gameState.selectedPosition, equals(Position.fromNotation('b2')));
      expect(gameState.legalMoves.contains(Position.fromNotation('b3')), isTrue);

      // Move knight to b3
      gameState.handleCellTap(Position.fromNotation('b3'));
      expect(gameState.board[Position.fromNotation('b3')]?.type, equals(PieceType.knight));
      expect(gameState.board[Position.fromNotation('b2')], isNull);

      // Turn is now Red
      expect(gameState.currentTurn, equals(PlayerSide.red));

      // Red selects knight at b12 and moves to b11
      gameState.handleCellTap(Position.fromNotation('b12'));
      expect(gameState.selectedPosition, equals(Position.fromNotation('b12')));
      gameState.handleCellTap(Position.fromNotation('b11'));

      // Turn is now Blue again
      expect(gameState.currentTurn, equals(PlayerSide.blue));
    });
  });

  group('Targeting Rules', () {
    test('Front attack direction: Blue forward vs Red forward', () {
      final board = <Position, Piece>{
        Position.fromNotation('d5'): Piece(
          id: 'blue_tank',
          type: PieceType.tank, // Front, range 1
          side: PlayerSide.blue,
        ),
        Position.fromNotation('d6'): Piece(
          id: 'red_enemy_front',
          type: PieceType.tank,
          side: PlayerSide.red,
        ),
        Position.fromNotation('d4'): Piece(
          id: 'red_enemy_back',
          type: PieceType.tank,
          side: PlayerSide.red,
        ),
        Position.fromNotation('e5'): Piece(
          id: 'red_enemy_side',
          type: PieceType.tank,
          side: PlayerSide.red,
        ),
      };

      final blueTargets = getAttackTargets(from: Position.fromNotation('d5'), board: board);
      expect(blueTargets, contains(Position.fromNotation('d6')));
      expect(blueTargets.contains(Position.fromNotation('d4')), isFalse);
      expect(blueTargets.contains(Position.fromNotation('e5')), isFalse);

      // For Red, forward is decreasing row (d5 -> d4)
      board[Position.fromNotation('d5')] = Piece(
        id: 'red_tank',
        type: PieceType.tank,
        side: PlayerSide.red,
      );
      board[Position.fromNotation('d4')] = Piece(
        id: 'blue_enemy_down',
        type: PieceType.tank,
        side: PlayerSide.blue,
      );

      final redTargets = getAttackTargets(from: Position.fromNotation('d5'), board: board);
      expect(redTargets, contains(Position.fromNotation('d4')));
      expect(redTargets.contains(Position.fromNotation('d6')), isFalse);
    });

    test('Front/Diag attack direction and range limit', () {
      final board = <Position, Piece>{
        Position.fromNotation('d5'): Piece(
          id: 'blue_arc',
          type: PieceType.archer, // FrontDiagonal, range 4
          side: PlayerSide.blue,
        ),
        Position.fromNotation('d6'): Piece(id: 'e1', type: PieceType.tank, side: PlayerSide.red), // Front
        Position.fromNotation('e6'): Piece(id: 'e2', type: PieceType.tank, side: PlayerSide.red), // Diag up-right
        Position.fromNotation('c6'): Piece(id: 'e3', type: PieceType.tank, side: PlayerSide.red), // Diag up-left
        Position.fromNotation('e4'): Piece(id: 'e4', type: PieceType.tank, side: PlayerSide.red), // Diag down-right
        Position.fromNotation('c4'): Piece(id: 'e5', type: PieceType.tank, side: PlayerSide.red), // Diag down-left
        Position.fromNotation('d4'): Piece(id: 'e6', type: PieceType.tank, side: PlayerSide.red), // Back orthogonal (not diag)
        Position.fromNotation('e5'): Piece(id: 'e7', type: PieceType.tank, side: PlayerSide.red), // Side orthogonal
      };

      final targets = getAttackTargets(from: Position.fromNotation('d5'), board: board);
      expect(targets, contains(Position.fromNotation('d6')));
      expect(targets, contains(Position.fromNotation('e6')));
      expect(targets, contains(Position.fromNotation('c6')));
      expect(targets, contains(Position.fromNotation('e4')));
      expect(targets, contains(Position.fromNotation('c4')));
      expect(targets.contains(Position.fromNotation('d4')), isFalse);
      expect(targets.contains(Position.fromNotation('e5')), isFalse);
    });

    test('All attack direction and Dormant Phantom exclusion', () {
      final board = <Position, Piece>{
        Position.fromNotation('d5'): Piece(
          id: 'phn',
          type: PieceType.phantom, // All, range 1
          side: PlayerSide.blue,
        ),
        Position.fromNotation('d4'): Piece(id: 'e1', type: PieceType.tank, side: PlayerSide.red),
        Position.fromNotation('d6'): Piece(id: 'e2', type: PieceType.tank, side: PlayerSide.red),
        Position.fromNotation('e5'): Piece(id: 'e3', type: PieceType.tank, side: PlayerSide.red),
      };

      final phnTargets = getAttackTargets(from: Position.fromNotation('d5'), board: board);
      expect(phnTargets.length, equals(3));

      // Dormant Phantom cannot attack
      board[Position.fromNotation('d5')] = Piece(
        id: 'phn_dormant',
        type: PieceType.phantom,
        side: PlayerSide.blue,
        isDormant: true,
      );
      final dormantTargets = getAttackTargets(from: Position.fromNotation('d5'), board: board);
      expect(dormantTargets, isEmpty);
    });

    test('Range limit: Scepter range 2', () {
      final board = <Position, Piece>{
        Position.fromNotation('d5'): Piece(
          id: 'scp',
          type: PieceType.scepter, // Range 2, All
          side: PlayerSide.blue,
        ),
        Position.fromNotation('d7'): Piece(id: 'in_range', type: PieceType.tank, side: PlayerSide.red),
        Position.fromNotation('f5'): Piece(id: 'in_range2', type: PieceType.tank, side: PlayerSide.red),
        Position.fromNotation('d8'): Piece(id: 'out_of_range', type: PieceType.tank, side: PlayerSide.red),
      };

      final targets = getAttackTargets(from: Position.fromNotation('d5'), board: board);
      expect(targets, contains(Position.fromNotation('d7')));
      expect(targets, contains(Position.fromNotation('f5')));
      expect(targets.contains(Position.fromNotation('d8')), isFalse);
    });

    test('Human shield: first piece blocks line of sight', () {
      final board = <Position, Piece>{
        Position.fromNotation('d5'): Piece(
          id: 'arc',
          type: PieceType.archer, // Range 4
          side: PlayerSide.blue,
        ),
        Position.fromNotation('d6'): Piece(id: 'enemy_first', type: PieceType.tank, side: PlayerSide.red),
        Position.fromNotation('d7'): Piece(id: 'enemy_second', type: PieceType.tank, side: PlayerSide.red),
      };

      final targets = getAttackTargets(from: Position.fromNotation('d5'), board: board);
      expect(targets, contains(Position.fromNotation('d6')));
      expect(targets.contains(Position.fromNotation('d7')), isFalse);
    });

    test('Friendly piece blocks line of sight', () {
      final board = <Position, Piece>{
        Position.fromNotation('d5'): Piece(
          id: 'arc',
          type: PieceType.archer, // Range 4
          side: PlayerSide.blue,
        ),
        Position.fromNotation('d6'): Piece(id: 'friend_first', type: PieceType.tank, side: PlayerSide.blue),
        Position.fromNotation('d7'): Piece(id: 'enemy_behind', type: PieceType.tank, side: PlayerSide.red),
      };

      final targets = getAttackTargets(from: Position.fromNotation('d5'), board: board);
      expect(targets, isEmpty);
    });

    test('River does not block attack line of sight', () {
      // d7 is a river square. Scepter at d6 has range 2. Enemy at d8 (across river).
      final board = <Position, Piece>{
        Position.fromNotation('d6'): Piece(
          id: 'scp',
          type: PieceType.scepter, // Range 2
          side: PlayerSide.blue,
        ),
        Position.fromNotation('d8'): Piece(
          id: 'enemy',
          type: PieceType.tank,
          side: PlayerSide.red,
        ),
      };

      final targets = getAttackTargets(from: Position.fromNotation('d6'), board: board);
      expect(targets, contains(Position.fromNotation('d8')));
    });
  });

  group('Damage and Removal Rules', () {
    test('Normal attack absorbs armor first then hits HP', () {
      final attacker = Piece(id: 'kn', type: PieceType.knight, side: PlayerSide.blue); // atk 1
      final defender = Piece(id: 'tnk', type: PieceType.tank, side: PlayerSide.red); // hp 3, armor 3

      applyAttackDamage(attacker: attacker, defender: defender);
      expect(defender.currentArmor, equals(2));
      expect(defender.currentHp, equals(3));

      // Hit with 3 damage
      final strongAttacker = Piece(id: 'phn', type: PieceType.phantom, side: PlayerSide.blue); // atk 3
      applyAttackDamage(attacker: strongAttacker, defender: defender);
      // Armor was 2 -> 3 damage breaks 2 armor and deals 1 to HP
      expect(defender.currentArmor, equals(0));
      expect(defender.currentHp, equals(2));
    });

    test('Mage burn ignores armor and goes straight to HP', () {
      final mage = Piece(id: 'mge', type: PieceType.mage, side: PlayerSide.blue); // atk 2
      final tank = Piece(id: 'tnk', type: PieceType.tank, side: PlayerSide.red); // hp 3, armor 3

      applyAttackDamage(attacker: mage, defender: tank);
      expect(tank.currentArmor, equals(3));
      expect(tank.currentHp, equals(1));
    });

    test('Removal at HP <= 0 and Crown assassination triggers game over', () {
      final gameState = GameState(initialPhase: GamePhase.play);
      // Replace board with attacker and Crown
      final phantomPos = Position.fromNotation('e5');
      final crownPos = Position.fromNotation('e6');

      gameState.board.clear();
      gameState.board[phantomPos] = Piece(id: 'phn', type: PieceType.phantom, side: PlayerSide.blue); // atk 3
      gameState.board[crownPos] = Piece(id: 'crn', type: PieceType.crown, side: PlayerSide.red); // hp 1, armor 1

      // Blue selects Phantom
      gameState.handleCellTap(phantomPos);
      expect(gameState.attackTargets, contains(crownPos));

      // Blue attacks Crown
      gameState.handleCellTap(crownPos);

      // Crown is removed
      expect(gameState.board.containsKey(crownPos), isFalse);
      // Blue wins immediately
      expect(gameState.isGameOver, isTrue);
      expect(gameState.winner, equals(PlayerSide.blue));

      // Input is disabled when game is over
      gameState.handleCellTap(phantomPos);
      expect(gameState.selectedPosition, isNull);
    });

    test('Fresh Scepter also kills fresh Crown', () {
      final scepter = Piece(id: 'scp', type: PieceType.scepter, side: PlayerSide.blue); // atk 2
      final crown = Piece(id: 'crn', type: PieceType.crown, side: PlayerSide.red); // hp 1, armor 1

      applyAttackDamage(attacker: scepter, defender: crown);
      // Atk 2 against armor 1: armor absorbed 1, 1 hits hp -> hp 0 -> dead
      expect(crown.currentHp, equals(0));
    });
  });

  group('Turn Actions and Target Selection', () {
    test('when a piece has a target, moving a different piece is allowed', () {
      final gameState = GameState(initialPhase: GamePhase.play);
      gameState.board.clear();

      // Pass turn to Red by having Blue make a move
      final blueTemp = Position.fromNotation('a1');
      final blueDest = Position.fromNotation('a2');
      gameState.board[blueTemp] = Piece(id: 'blue_starter', type: PieceType.knight, side: PlayerSide.blue);
      gameState.handleCellTap(blueTemp);
      gameState.handleCellTap(blueDest);
      expect(gameState.currentTurn, equals(PlayerSide.red));

      // Setup bug scenario: Blue Phantom on e7, Red Archer on e9, Red Knight on b12
      final e7 = Position.fromNotation('e7');
      final e9 = Position.fromNotation('e9');
      final b12 = Position.fromNotation('b12');
      final b11 = Position.fromNotation('b11');

      gameState.board[e7] = Piece(id: 'blue_phn', type: PieceType.phantom, side: PlayerSide.blue);
      gameState.board[e9] = Piece(id: 'red_arc', type: PieceType.archer, side: PlayerSide.red);
      gameState.board[b12] = Piece(id: 'red_kn', type: PieceType.knight, side: PlayerSide.red);

      // Verify Red Archer on e9 has Blue Phantom on e7 as target
      gameState.handleCellTap(e9);
      expect(gameState.attackTargets, contains(e7));

      // Select a different Red piece (Knight at b12)
      gameState.handleCellTap(b12);
      expect(gameState.selectedPosition, equals(b12));
      // Red Knight must be able to move normally
      expect(gameState.legalMoves, contains(b11));

      // Move the Knight to b11
      gameState.handleCellTap(b11);
      expect(gameState.board[b11]?.type, equals(PieceType.knight));
      expect(gameState.board[b12], isNull);
      // Turn passes to Blue
      expect(gameState.currentTurn, equals(PlayerSide.blue));
    });

    test('selecting a piece with no targets yields an empty target list', () {
      final gameState = GameState(initialPhase: GamePhase.play);
      gameState.board.clear();

      final blueKnightPos = Position.fromNotation('b2');
      gameState.board[blueKnightPos] = Piece(
        id: 'blue_kn',
        type: PieceType.knight,
        side: PlayerSide.blue,
      );

      // No enemy pieces around
      gameState.handleCellTap(blueKnightPos);
      expect(gameState.selectedPosition, equals(blueKnightPos));
      expect(gameState.attackTargets, isEmpty);
      expect(gameState.legalMoves, isNotEmpty);
    });
  });

  group('Healer and Poison Rules', () {
    test('heal cap at starting hp and heal cures poison', () {
      final gameState = GameState(initialPhase: GamePhase.play);
      gameState.board.clear();

      final healerPos = Position.fromNotation('c1');
      final allyTankPos = Position.fromNotation('c2');

      final allyTank = Piece(
        id: 'ally_tank',
        type: PieceType.tank, // max hp 3, armor 3
        side: PlayerSide.blue,
        currentHp: 2,
        poisonTurns: 2,
      );

      gameState.board[healerPos] = Piece(id: 'hlr', type: PieceType.healer, side: PlayerSide.blue);
      gameState.board[allyTankPos] = allyTank;

      // Select Healer
      gameState.handleCellTap(healerPos);
      expect(gameState.healTargets, contains(allyTankPos));

      // Heal ally
      gameState.handleCellTap(allyTankPos);
      expect(allyTank.currentHp, equals(3)); // capped at starting hp (3)
      expect(allyTank.isPoisoned, isFalse); // poison cured
      expect(allyTank.poisonTurns, equals(0));

      // After healing, ally is at full hp and not poisoned -> cannot be healed again
      gameState.startPlay();
      gameState.board.clear();
      gameState.board[healerPos] = Piece(id: 'hlr', type: PieceType.healer, side: PlayerSide.blue);
      gameState.board[allyTankPos] = Piece(id: 'full_tank', type: PieceType.tank, side: PlayerSide.blue); // hp 3

      gameState.handleCellTap(healerPos);
      expect(gameState.healTargets, isEmpty);
    });

    test('heal ignores line of sight but respects range 4', () {
      final board = <Position, Piece>{
        Position.fromNotation('d1'): Piece(id: 'hlr', type: PieceType.healer, side: PlayerSide.blue),
        Position.fromNotation('d2'): Piece(id: 'p1', type: PieceType.knight, side: PlayerSide.blue),
        Position.fromNotation('d3'): Piece(id: 'p2', type: PieceType.tank, side: PlayerSide.red), // Enemy in between
        Position.fromNotation('d4'): Piece(id: 'target', type: PieceType.tank, side: PlayerSide.blue, currentHp: 1), // Ally dist 3
        Position.fromNotation('d6'): Piece(id: 'out_of_range', type: PieceType.tank, side: PlayerSide.blue, currentHp: 1), // Ally dist 5 (out of range)
      };

      final healTargets = getHealerHealTargets(from: Position.fromNotation('d1'), board: board);
      // d4 is within range 4 and line of sight is ignored
      expect(healTargets, contains(Position.fromNotation('d4')));
      // d6 is dist 5, out of range 4
      expect(healTargets.contains(Position.fromNotation('d6')), isFalse);
    });

    test('poison is blocked by a piece in front', () {
      final board = <Position, Piece>{
        Position.fromNotation('d1'): Piece(id: 'hlr', type: PieceType.healer, side: PlayerSide.blue),
        Position.fromNotation('d2'): Piece(id: 'friend', type: PieceType.knight, side: PlayerSide.blue),
        Position.fromNotation('d3'): Piece(id: 'enemy', type: PieceType.tank, side: PlayerSide.red),
      };

      final poisonTargets = getAttackTargets(from: Position.fromNotation('d1'), board: board);
      // Friendly knight at d2 blocks poison line of sight
      expect(poisonTargets, isEmpty);
    });

    test('poison -1 hp ignores armor and cannot target an already poisoned piece', () {
      final gameState = GameState(initialPhase: GamePhase.play);
      gameState.board.clear();

      final healerPos = Position.fromNotation('d1');
      final enemyPos = Position.fromNotation('d3');
      final enemyTank = Piece(id: 'enemy_tank', type: PieceType.tank, side: PlayerSide.red); // hp 3, armor 3

      gameState.board[healerPos] = Piece(id: 'hlr', type: PieceType.healer, side: PlayerSide.blue);
      gameState.board[enemyPos] = enemyTank;

      gameState.handleCellTap(healerPos);
      expect(gameState.attackTargets, contains(enemyPos));

      // Poison the enemy
      gameState.handleCellTap(enemyPos);
      expect(enemyTank.currentArmor, equals(3)); // armor ignored!
      expect(enemyTank.currentHp, equals(2)); // -1 hp immediately
      expect(enemyTank.poisonTurns, equals(2)); // poison turns set to 2

      // Now pass turn back to Blue to verify poison cannot target already poisoned piece
      gameState.board[Position.fromNotation('a13')] = Piece(id: 'red_pass', type: PieceType.knight, side: PlayerSide.red);
      gameState.handleCellTap(Position.fromNotation('a13'));
      gameState.handleCellTap(Position.fromNotation('a12'));
      expect(gameState.currentTurn, equals(PlayerSide.blue));

      gameState.handleCellTap(healerPos);
      expect(gameState.attackTargets.contains(enemyPos), isFalse); // Cannot target already poisoned piece!
    });

    test('tick timeline: hit on turn T, extra -1 at the end of victim owner 2nd turn', () {
      final gameState = GameState(initialPhase: GamePhase.play);
      gameState.board.clear();

      final healerPos = Position.fromNotation('d1');
      final enemyPos = Position.fromNotation('d3');
      final enemyTank = Piece(id: 'enemy_tank', type: PieceType.tank, side: PlayerSide.red); // hp 3, armor 3
      final redDummyPos = Position.fromNotation('k13');
      final blueDummyPos = Position.fromNotation('a1');

      gameState.board[healerPos] = Piece(id: 'hlr', type: PieceType.healer, side: PlayerSide.blue);
      gameState.board[enemyPos] = enemyTank;
      gameState.board[redDummyPos] = Piece(id: 'red_d', type: PieceType.knight, side: PlayerSide.red);
      gameState.board[blueDummyPos] = Piece(id: 'blue_d', type: PieceType.knight, side: PlayerSide.blue);

      // Turn T (Blue's turn): Blue poisons Red Tank
      gameState.handleCellTap(healerPos);
      gameState.handleCellTap(enemyPos);
      expect(enemyTank.currentHp, equals(2));
      expect(enemyTank.poisonTurns, equals(2));
      expect(gameState.currentTurn, equals(PlayerSide.red));

      // Red Turn 1: Red moves dummy piece
      gameState.handleCellTap(redDummyPos);
      gameState.handleCellTap(Position.fromNotation('k12'));
      // At end of Red Turn 1: poison decrements to 1, no damage yet
      expect(enemyTank.poisonTurns, equals(1));
      expect(enemyTank.currentHp, equals(2));
      expect(gameState.currentTurn, equals(PlayerSide.blue));

      // Blue Turn T+1: Blue moves dummy piece
      gameState.handleCellTap(blueDummyPos);
      gameState.handleCellTap(Position.fromNotation('a2'));
      expect(enemyTank.poisonTurns, equals(1)); // Red's piece does not tick on Blue's turn
      expect(enemyTank.currentHp, equals(2));
      expect(gameState.currentTurn, equals(PlayerSide.red));

      // Red Turn 2: Red moves dummy piece
      gameState.handleCellTap(Position.fromNotation('k12'));
      gameState.handleCellTap(Position.fromNotation('k11'));
      // At end of Red Turn 2: poison decrements 1 -> 0, deals extra -1 HP and cures
      expect(enemyTank.poisonTurns, equals(0));
      expect(enemyTank.isPoisoned, isFalse);
      expect(enemyTank.currentHp, equals(1)); // extra -1 applied!
    });

    test('poison can kill immediately and triggers game over if Crown dies', () {
      final gameState = GameState(initialPhase: GamePhase.play);
      gameState.board.clear();

      final healerPos = Position.fromNotation('d1');
      final crownPos = Position.fromNotation('d3');
      final crown = Piece(id: 'crn', type: PieceType.crown, side: PlayerSide.red); // hp 1, armor 1

      gameState.board[healerPos] = Piece(id: 'hlr', type: PieceType.healer, side: PlayerSide.blue);
      gameState.board[crownPos] = crown;

      gameState.handleCellTap(healerPos);
      gameState.handleCellTap(crownPos);

      // Crown dies from upfront -1 HP (ignores armor 1)
      expect(gameState.board.containsKey(crownPos), isFalse);
      expect(gameState.isGameOver, isTrue);
      expect(gameState.winner, equals(PlayerSide.blue));
    });
  });

  group('Summon Rules', () {
    test('summon works once, places only on empty non-river squares adjacent to Crown, and makes Phantom dormant', () {
      final gameState = GameState(initialPhase: GamePhase.play);
      gameState.board.clear();

      // Crown at d6 (row 6, below river row 7). River is d7!
      final crownPos = Position.fromNotation('d6');
      final phantomPos = Position.fromNotation('a1');
      final occupiedNeighbor = Position.fromNotation('c5');

      gameState.board[crownPos] = Piece(id: 'crn', type: PieceType.crown, side: PlayerSide.blue);
      gameState.board[phantomPos] = Piece(id: 'phn', type: PieceType.phantom, side: PlayerSide.blue);
      gameState.board[occupiedNeighbor] = Piece(id: 'blocker', type: PieceType.tank, side: PlayerSide.blue);

      expect(gameState.canCurrentPlayerSummon, isTrue);

      final destinations = getSummonDestinations(side: PlayerSide.blue, board: gameState.board);
      // d7 is river -> must NOT be in destinations!
      expect(destinations.contains(Position.fromNotation('d7')), isFalse);
      // c5 is occupied -> must NOT be in destinations!
      expect(destinations.contains(occupiedNeighbor), isFalse);
      // e7 is bridge -> CAN be in destinations!
      expect(destinations.contains(Position.fromNotation('e7')), isTrue);
      // d5 is empty adjacent -> CAN be in destinations!
      expect(destinations.contains(Position.fromNotation('d5')), isTrue);

      // Start summon
      gameState.toggleSummon();
      expect(gameState.isSummoning, isTrue);

      // Tap e7 to summon Phantom
      gameState.handleCellTap(Position.fromNotation('e7'));

      // Phantom is teleported to e7 and removed from a1
      expect(gameState.board[Position.fromNotation('e7')]?.type, equals(PieceType.phantom));
      expect(gameState.board.containsKey(phantomPos), isFalse);

      final summonedPhantom = gameState.board[Position.fromNotation('e7')]!;
      expect(summonedPhantom.isDormant, isTrue);
      expect(gameState.blueSummonUsed, isTrue);

      // Summon ends turn -> now Red's turn
      expect(gameState.currentTurn, equals(PlayerSide.red));

      // Put an enemy near summoned phantom to test dormancy
      gameState.board[Position.fromNotation('e8')] = Piece(id: 'red_enemy', type: PieceType.tank, side: PlayerSide.red);

      // Pass Red's turn
      gameState.board[Position.fromNotation('k13')] = Piece(id: 'red_d', type: PieceType.knight, side: PlayerSide.red);
      gameState.handleCellTap(Position.fromNotation('k13'));
      gameState.handleCellTap(Position.fromNotation('k12'));

      // Now Blue's next turn: summoned Phantom should wake up
      expect(gameState.currentTurn, equals(PlayerSide.blue));
      expect(summonedPhantom.isDormant, isFalse);

      // Blue selects Phantom: now it CAN attack enemy at e8!
      gameState.handleCellTap(Position.fromNotation('e7'));
      expect(gameState.attackTargets, contains(Position.fromNotation('e8')));

      // Blue summon is used, cannot summon again
      expect(gameState.canCurrentPlayerSummon, isFalse);
    });

    test('summon disabled if Phantom is dead', () {
      final gameState = GameState(initialPhase: GamePhase.play);
      gameState.board.clear();

      final crownPos = Position.fromNotation('d6');
      gameState.board[crownPos] = Piece(id: 'crn', type: PieceType.crown, side: PlayerSide.blue);
      // No Phantom on board

      expect(gameState.canCurrentPlayerSummon, isFalse);
      expect(getSummonDestinations(side: PlayerSide.blue, board: gameState.board), isEmpty);
    });
  });

  group('Deployment Phase Rules', () {
    test('placement is rejected outside the player rows and on occupied squares', () {
      final gameState = GameState(); // Starts in blueDeployment
      expect(gameState.phase, equals(GamePhase.blueDeployment));

      // Select Tank
      gameState.selectTrayPiece(PieceType.tank);
      expect(gameState.selectedTrayPiece, equals(PieceType.tank));

      // Attempt to place on row 4 (outside Blue rows 1-3)
      final row4Pos = Position.fromNotation('a4');
      final placedRow4 = gameState.placePiece(row4Pos);
      expect(placedRow4, isFalse);
      expect(gameState.board.containsKey(row4Pos), isFalse);
      expect(gameState.blueRemainingPieces[PieceType.tank], equals(4));

      // Place validly on row 1 (c1)
      final c1 = Position.fromNotation('c1');
      final placedC1 = gameState.placePiece(c1);
      expect(placedC1, isTrue);
      expect(gameState.board[c1]?.type, equals(PieceType.tank));
      expect(gameState.blueRemainingPieces[PieceType.tank], equals(3));

      // Attempt to place on occupied square (c1)
      gameState.selectTrayPiece(PieceType.tank);
      final placedAgain = gameState.placePiece(c1);
      expect(placedAgain, isFalse);
      expect(gameState.blueRemainingPieces[PieceType.tank], equals(3));

      // Attempt to place on fixed Phantom square (a1)
      final placedOnFixed = gameState.placePiece(Position.fromNotation('a1'));
      expect(placedOnFixed, isFalse);
    });

    test('fixed pieces cannot be removed', () {
      final gameState = GameState();

      // Fixed Phantom a1 and Scepter k1
      final a1 = Position.fromNotation('a1');
      final k1 = Position.fromNotation('k1');

      expect(gameState.removePiece(a1), isFalse);
      expect(gameState.board[a1]?.type, equals(PieceType.phantom));

      expect(gameState.removePiece(k1), isFalse);
      expect(gameState.board[k1]?.type, equals(PieceType.scepter));

      // Place and remove a non-fixed piece
      gameState.selectTrayPiece(PieceType.tank);
      final c1 = Position.fromNotation('c1');
      gameState.placePiece(c1);
      expect(gameState.blueRemainingPieces[PieceType.tank], equals(3));

      // Pick it back up
      expect(gameState.removePiece(c1), isTrue);
      expect(gameState.board.containsKey(c1), isFalse);
      expect(gameState.blueRemainingPieces[PieceType.tank], equals(4));
    });

    test('Done is disabled until 22 pieces are placed', () {
      final gameState = GameState();
      expect(gameState.canCompleteDeployment(PlayerSide.blue), isFalse);

      // Attempting to complete deployment should not advance phase
      gameState.completeDeployment();
      expect(gameState.phase, equals(GamePhase.blueDeployment));
    });

    test('counts per type are enforced', () {
      final gameState = GameState();
      gameState.selectTrayPiece(PieceType.crown);

      // Place 1 Crown
      final b1 = Position.fromNotation('b1');
      expect(gameState.placePiece(b1), isTrue);
      expect(gameState.blueRemainingPieces[PieceType.crown], equals(0));

      // Attempt to place another Crown
      gameState.selectTrayPiece(PieceType.crown);
      expect(gameState.selectedTrayPiece, isNull); // Cannot select when count is 0
      final b2 = Position.fromNotation('b2');
      expect(gameState.placePiece(b2), isFalse);
    });

    test('Auto-fill produces a valid complete layout for both sides and transitions to play', () {
      final gameState = GameState();
      expect(gameState.phase, equals(GamePhase.blueDeployment));

      // Blue auto-fill
      gameState.autoFill(PlayerSide.blue);
      expect(gameState.canCompleteDeployment(PlayerSide.blue), isTrue);
      expect(gameState.blueRemainingPieces.values.every((c) => c == 0), isTrue);

      final bluePieces = gameState.board.values.where((p) => p.side == PlayerSide.blue).toList();
      expect(bluePieces.length, equals(22));

      // Blue taps Done -> transitions to passToRed
      gameState.completeDeployment();
      expect(gameState.phase, equals(GamePhase.passToRed));

      // Red takes device -> redDeployment
      gameState.continueFromHandover();
      expect(gameState.phase, equals(GamePhase.redDeployment));

      // Red auto-fill
      gameState.autoFill(PlayerSide.red);
      expect(gameState.canCompleteDeployment(PlayerSide.red), isTrue);
      expect(gameState.redRemainingPieces.values.every((c) => c == 0), isTrue);

      final redPieces = gameState.board.values.where((p) => p.side == PlayerSide.red).toList();
      expect(redPieces.length, equals(22));

      // Red taps Done -> transitions to passToBlue
      gameState.completeDeployment();
      expect(gameState.phase, equals(GamePhase.passToBlue));

      // Blue takes device -> play starts!
      gameState.continueFromHandover();
      expect(gameState.phase, equals(GamePhase.play));
      expect(gameState.currentTurn, equals(PlayerSide.blue));
    });
  });
}
