import 'package:flutter/material.dart';

enum PlayerSide {
  blue,
  red,
}

enum PieceType {
  tank,
  healer,
  archer,
  mage,
  knight,
  phantom,
  crown,
  scepter,
}

enum AttackDirection {
  front,
  frontDiagonal,
  all,
}

class PieceDefinition {
  final PieceType type;
  final String name;
  final String abbreviation;
  final int moveDistance;
  final int atk;
  final int range;
  final AttackDirection attackDirection;
  final int hp;
  final int armor;

  const PieceDefinition({
    required this.type,
    required this.name,
    required this.abbreviation,
    required this.moveDistance,
    required this.atk,
    required this.range,
    required this.attackDirection,
    required this.hp,
    required this.armor,
  });
}

const Map<PieceType, PieceDefinition> pieceDefinitions = {
  PieceType.tank: PieceDefinition(
    type: PieceType.tank,
    name: 'Tank',
    abbreviation: 'Tnk',
    moveDistance: 1,
    atk: 1,
    range: 1,
    attackDirection: AttackDirection.front,
    hp: 3,
    armor: 3,
  ),
  PieceType.healer: PieceDefinition(
    type: PieceType.healer,
    name: 'Healer',
    abbreviation: 'Hlr',
    moveDistance: 1,
    atk: 1,
    range: 4,
    attackDirection: AttackDirection.all,
    hp: 2,
    armor: 2,
  ),
  PieceType.archer: PieceDefinition(
    type: PieceType.archer,
    name: 'Archer',
    abbreviation: 'Arc',
    moveDistance: 1,
    atk: 1,
    range: 4,
    attackDirection: AttackDirection.frontDiagonal,
    hp: 2,
    armor: 0,
  ),
  PieceType.mage: PieceDefinition(
    type: PieceType.mage,
    name: 'Mage',
    abbreviation: 'Mge',
    moveDistance: 1,
    atk: 2,
    range: 3,
    attackDirection: AttackDirection.frontDiagonal,
    hp: 2,
    armor: 2,
  ),
  PieceType.knight: PieceDefinition(
    type: PieceType.knight,
    name: 'Knight',
    abbreviation: 'Kn',
    moveDistance: 2,
    atk: 1,
    range: 1,
    attackDirection: AttackDirection.front,
    hp: 2,
    armor: 3,
  ),
  PieceType.phantom: PieceDefinition(
    type: PieceType.phantom,
    name: 'Phantom',
    abbreviation: 'Phn',
    moveDistance: 3,
    atk: 3,
    range: 1,
    attackDirection: AttackDirection.all,
    hp: 1,
    armor: 1,
  ),
  PieceType.crown: PieceDefinition(
    type: PieceType.crown,
    name: 'Crown',
    abbreviation: 'Crn',
    moveDistance: 1,
    atk: 1,
    range: 1,
    attackDirection: AttackDirection.all,
    hp: 1,
    armor: 1,
  ),
  PieceType.scepter: PieceDefinition(
    type: PieceType.scepter,
    name: 'Scepter',
    abbreviation: 'Scp',
    moveDistance: 4,
    atk: 2,
    range: 2,
    attackDirection: AttackDirection.all,
    hp: 1,
    armor: 1,
  ),
};

class Piece {
  final String id;
  final PieceType type;
  final PlayerSide side;
  int currentHp;
  int currentArmor;
  int poisonTurns;
  bool isDormant;

  Piece({
    required this.id,
    required this.type,
    required this.side,
    int? currentHp,
    int? currentArmor,
    this.poisonTurns = 0,
    this.isDormant = false,
  })  : currentHp = currentHp ?? pieceDefinitions[type]!.hp,
        currentArmor = currentArmor ?? pieceDefinitions[type]!.armor;

  PieceDefinition get definition => pieceDefinitions[type]!;
  bool get isPoisoned => poisonTurns > 0;
}

extension AttackDirectionDisplay on AttackDirection {
  String get displayName {
    switch (this) {
      case AttackDirection.front:
        return 'Front';
      case AttackDirection.frontDiagonal:
        return 'Front / Diag';
      case AttackDirection.all:
        return 'All';
    }
  }
}

class Position {
  final int col; // 0..10 for columns a..k
  final int row; // 1..13

  const Position(this.col, this.row);

  String get colName => String.fromCharCode('a'.codeUnitAt(0) + col);
  String get notation => '$colName$row';

  static Position fromNotation(String notation) {
    final col = notation.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = int.parse(notation.substring(1));
    return Position(col, row);
  }

  bool get isOnBoard => col >= 0 && col < boardCols && row >= 1 && row <= boardRows;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          col == other.col &&
          row == other.row;

  @override
  int get hashCode => col.hashCode ^ row.hashCode;

  @override
  String toString() => notation;
}

// Board Constants
const int boardCols = 11;
const int boardRows = 13;
const int riverRow = 7;

const Set<int> riverCols = {0, 3, 7, 10}; // a, d, h, k
const Set<int> bridgeCols = {1, 2, 4, 5, 6, 8, 9}; // b, c, e, f, g, i, j

bool isRiverPosition(Position pos) => pos.row == riverRow && riverCols.contains(pos.col);
bool isBridgePosition(Position pos) => pos.row == riverRow && bridgeCols.contains(pos.col);

// Theme Colors
const Color appBackgroundColor = Color(0xFF121212);
const Color cellNormalColor = Color(0xFF1E2126);
const Color cellRiverColor = Color(0xFF1F4E79);
const Color cellBridgeColor = Color(0xFF8B5E34);
const Color pieceBlueColor = Color(0xFF6EA8FF);
const Color pieceRedColor = Color(0xFFFF7B7B);
const Color selectionOutlineColor = Color(0xFFFFD54F);
const Color legalMoveGreenColor = Color(0xFF4CAF50);
const Color attackTargetRedOutline = Color(0xFFFF5252);
const Color healTargetGreenOutline = Color(0xFF66BB6A);
const Color summonHighlightColor = Color(0xFF00E5FF);

