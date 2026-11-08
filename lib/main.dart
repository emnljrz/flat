import 'package:flutter/material.dart';
import 'models.dart';
import 'game_state.dart';

void main() {
  runApp(const TheBoredGameApp());
}

class TheBoredGameApp extends StatelessWidget {
  const TheBoredGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Bored Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: appBackgroundColor,
        colorScheme: const ColorScheme.dark(
          surface: appBackgroundColor,
        ),
      ),
      home: const BoardScreen(),
    );
  }
}

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late final GameState _gameState;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
  }

  @override
  void dispose() {
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _gameState,
          builder: (context, _) {
            final turn = _gameState.currentTurn;
            final turnColor = turn == PlayerSide.blue ? pieceBlueColor : pieceRedColor;
            final isGameOver = _gameState.isGameOver;
            final winner = _gameState.winner;

            return Column(
              children: [
                // Header: Turn indicator or Game Over banner
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isGameOver)
                        Row(
                          children: [
                            Text(
                              '👑 ${winner == PlayerSide.blue ? 'Blue' : 'Red'} Wins!',
                              style: TextStyle(
                                color: winner == PlayerSide.blue ? pieceBlueColor : pieceRedColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: turnColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              turn == PlayerSide.blue ? 'Blue to move' : 'Red to move',
                              style: TextStyle(
                                color: turnColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isGameOver && _gameState.canCurrentPlayerSummon)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _gameState.isSummoning ? summonHighlightColor : Colors.amberAccent,
                                side: BorderSide(
                                  color: _gameState.isSummoning ? summonHighlightColor : const Color(0x80FFD54F),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: Icon(
                                Icons.flash_on,
                                size: 14,
                                color: _gameState.isSummoning ? summonHighlightColor : Colors.amberAccent,
                              ),
                              label: Text(
                                _gameState.isSummoning ? 'Cancel' : 'Summon Phantom',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onPressed: _gameState.toggleSummon,
                            ),
                          const SizedBox(width: 4),
                          if (isGameOver)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2E35),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.replay, size: 18),
                              label: const Text('New game'),
                              onPressed: _gameState.reset,
                            )
                          else
                            IconButton(
                              tooltip: 'Reset Board',
                              icon: const Icon(Icons.refresh, size: 20, color: Colors.white70),
                              onPressed: _gameState.reset,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Info panel
                _buildInfoPanel(),
                // Board area
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: _buildBoardWithCoordinates(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    if (_gameState.isSummoning) {
      return Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: cellNormalColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x9900E5FF)),
        ),
        child: const Center(
          child: Text(
            'Tap a highlighted empty square adjacent to your Crown to summon',
            style: TextStyle(color: summonHighlightColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final piece = _gameState.selectedPiece;

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cellNormalColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: piece == null
          ? const Center(
              child: Text(
                'Tap any piece to view stats',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: piece.side == PlayerSide.blue ? pieceBlueColor : pieceRedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      piece.definition.name,
                      style: TextStyle(
                        color: piece.side == PlayerSide.blue ? pieceBlueColor : pieceRedColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (piece.type == PieceType.phantom && piece.isDormant) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '(zZ)',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                Text(
                  'HP: ${piece.currentHp}/${piece.definition.hp}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  'Armor: ${piece.currentArmor}/${piece.definition.armor}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  piece.type == PieceType.healer
                      ? 'Poison: 1'
                      : 'Atk: ${piece.definition.atk}${piece.type == PieceType.mage ? ' (Burn)' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Rng: ${piece.definition.range}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Dir: ${piece.definition.attackDirection.displayName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  piece.isPoisoned ? '☠ ${piece.poisonTurns}t' : 'Poison: -',
                  style: TextStyle(
                    color: piece.isPoisoned ? const Color(0xFFE040FB) : Colors.white54,
                    fontSize: 12,
                    fontWeight: piece.isPoisoned ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBoardWithCoordinates() {
    const double cellSize = 42.0;
    const double labelSize = 22.0;
    const colLabels = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k'];

    return Container(
      color: appBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top column labels
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: labelSize),
              for (int c = 0; c < boardCols; c++)
                SizedBox(
                  width: cellSize,
                  height: labelSize,
                  child: Center(
                    child: Text(
                      colLabels[c],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: labelSize),
            ],
          ),
          // Rows 13 down to 1
          for (int r = boardRows; r >= 1; r--)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left row label
                SizedBox(
                  width: labelSize,
                  height: cellSize,
                  child: Center(
                    child: Text(
                      '$r',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Grid cells
                for (int c = 0; c < boardCols; c++)
                  _buildCell(Position(c, r), cellSize),
                // Right row label
                SizedBox(
                  width: labelSize,
                  height: cellSize,
                  child: Center(
                    child: Text(
                      '$r',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          // Bottom column labels
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: labelSize),
              for (int c = 0; c < boardCols; c++)
                SizedBox(
                  width: cellSize,
                  height: labelSize,
                  child: Center(
                    child: Text(
                      colLabels[c],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: labelSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCell(Position pos, double size) {
    final piece = _gameState.board[pos];
    final isSelected = _gameState.selectedPosition == pos;
    final isLegalMove = _gameState.legalMoves.contains(pos);
    final isAttackTarget = _gameState.attackTargets.contains(pos);
    final isHealTarget = _gameState.healTargets.contains(pos);
    final isSummonDestination = _gameState.summonDestinations.contains(pos);

    // Cell base color according to theme
    Color cellBg;
    if (isRiverPosition(pos)) {
      cellBg = cellRiverColor;
    } else if (isBridgePosition(pos)) {
      cellBg = cellBridgeColor;
    } else {
      cellBg = cellNormalColor;
    }

    BoxBorder border;
    if (isAttackTarget) {
      border = Border.all(color: attackTargetRedOutline, width: 2.5);
    } else if (isHealTarget) {
      border = Border.all(color: healTargetGreenOutline, width: 2.5);
    } else if (isSummonDestination) {
      border = Border.all(color: summonHighlightColor, width: 2.5);
    } else if (isSelected) {
      border = Border.all(color: selectionOutlineColor, width: 2.5);
    } else {
      border = Border.all(color: Colors.black26, width: 0.5);
    }

    return GestureDetector(
      onTap: () => _gameState.handleCellTap(pos),
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(1.0),
        decoration: BoxDecoration(
          color: cellBg,
          border: border,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Summon destination indicator
            if (isSummonDestination)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: summonHighlightColor,
                  shape: BoxShape.circle,
                ),
              ),
            // Legal move destination indicator (green dot)
            if (isLegalMove)
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: legalMoveGreenColor,
                  shape: BoxShape.circle,
                ),
              ),
            // Piece text abbreviation + hp/armor
            if (piece != null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    piece.definition.abbreviation,
                    style: TextStyle(
                      color: piece.side == PlayerSide.blue ? pieceBlueColor : pieceRedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${piece.currentHp}/${piece.currentArmor}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            // Poison badge (skull + turns left)
            if (piece != null && piece.isPoisoned)
              Positioned(
                top: 1,
                left: 2,
                child: Text(
                  '☠${piece.poisonTurns}',
                  style: const TextStyle(
                    color: Color(0xFFE040FB),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Dormant marker on Phantom
            if (piece != null && piece.type == PieceType.phantom && piece.isDormant)
              const Positioned(
                top: 1,
                right: 2,
                child: Text(
                  'zZ',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
