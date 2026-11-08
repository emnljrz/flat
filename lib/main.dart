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
  bool _logExpanded = false;
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _gameState.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    if (_logExpanded && _logScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _gameState.removeListener(_onGameStateChanged);
    _gameState.dispose();
    _logScrollController.dispose();
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
            final phase = _gameState.phase;

            if (phase == GamePhase.passToRed) {
              return _buildHandoverScreen(PlayerSide.red);
            }
            if (phase == GamePhase.passToBlue) {
              return _buildHandoverScreen(PlayerSide.blue);
            }

            final isDeployment = _gameState.isDeployment;

            return Column(
              children: [
                if (isDeployment)
                  _buildDeploymentHeader()
                else
                  _buildPlayHeader(),
                if (isDeployment)
                  _buildDeploymentTray()
                else
                  _buildInfoPanel(),
                if (!isDeployment)
                  _buildLogPanel(),
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

  Widget _buildHandoverScreen(PlayerSide nextPlayer) {
    final sideColor = nextPlayer == PlayerSide.blue ? pieceBlueColor : pieceRedColor;
    final isToPlay = _gameState.phase == GamePhase.passToBlue;
    final title = nextPlayer == PlayerSide.blue ? 'Pass the device to Blue' : 'Pass the device to Red';
    final subtitle = isToPlay
        ? 'Deployment is complete. Blue moves first.'
        : 'Hand the device over for Red deployment.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horizontal_circle_outlined, size: 64, color: sideColor),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: sideColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2E35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _gameState.continueFromHandover,
              child: const Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeploymentHeader() {
    final currentSide = _gameState.deploymentSide;
    final sideColor = currentSide == PlayerSide.blue ? pieceBlueColor : pieceRedColor;
    final title = currentSide == PlayerSide.blue ? 'Blue: place your pieces' : 'Red: place your pieces';
    final canDone = _gameState.canCompleteDeployment();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: sideColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: sideColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _gameState.autoFill(),
                child: const Text('Auto-fill', style: TextStyle(fontSize: 11)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _gameState.clearDeployment(),
                child: const Text('Clear', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canDone ? sideColor : const Color(0xFF2A2E35),
                  foregroundColor: canDone ? Colors.black : Colors.white38,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: canDone ? _gameState.completeDeployment : null,
                child: const Text('Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeploymentTray() {
    final currentSide = _gameState.deploymentSide;
    final counts = _gameState.currentRemainingPieces;
    final selected = _gameState.selectedTrayPiece;
    final sideColor = currentSide == PlayerSide.blue ? pieceBlueColor : pieceRedColor;

    const types = [
      PieceType.crown,
      PieceType.knight,
      PieceType.tank,
      PieceType.healer,
      PieceType.archer,
      PieceType.mage,
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: cellNormalColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final type in types) ...[
            Builder(
              builder: (context) {
                final count = counts[type] ?? 0;
                final isSelected = selected == type;
                final isAvailable = count > 0;
                final def = pieceDefinitions[type]!;

                return GestureDetector(
                  onTap: isAvailable ? () => _gameState.selectTrayPiece(type) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2A323D) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? selectionOutlineColor
                            : (isAvailable ? Colors.white24 : Colors.transparent),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          def.abbreviation,
                          style: TextStyle(
                            color: isAvailable ? sideColor : Colors.white24,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'x$count',
                          style: TextStyle(
                            color: isAvailable ? Colors.white70 : Colors.white24,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayHeader() {
    final turn = _gameState.currentTurn;
    final turnColor = turn == PlayerSide.blue ? pieceBlueColor : pieceRedColor;
    final isGameOver = _gameState.isGameOver;
    final winner = _gameState.winner;
    final turnCounter = _gameState.turnCounter;

    return Container(
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
                const SizedBox(width: 10),
                Text(
                  'Turn $turnCounter',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
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
              IconButton(
                tooltip: 'Undo',
                icon: Icon(
                  Icons.undo,
                  size: 20,
                  color: _gameState.canUndo ? Colors.white70 : Colors.white24,
                ),
                onPressed: _gameState.canUndo ? _gameState.undo : null,
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

  Widget _buildLogPanel() {
    final log = _gameState.log;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: cellNormalColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _logExpanded = !_logExpanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  const Text('Combat Log', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text('(${log.length})', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  const Spacer(),
                  Icon(
                    _logExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
          if (_logExpanded)
            SizedBox(
              height: 110,
              child: log.isEmpty
                  ? const Center(child: Text('No events yet.', style: TextStyle(color: Colors.white24, fontSize: 11)))
                  : ListView.builder(
                      controller: _logScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      itemCount: log.length,
                      itemBuilder: (context, index) => Text(
                        log[index],
                        style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
                      ),
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
    final rawPiece = _gameState.board[pos];
    final piece = (rawPiece != null && _gameState.isPieceVisible(pos, rawPiece)) ? rawPiece : null;

    final isDeployment = _gameState.isDeployment;
    final currentSide = _gameState.deploymentSide;
    final inDeployZone = isDeployment && isInDeploymentZone(currentSide, pos);

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
    } else if (inDeployZone) {
      cellBg = currentSide == PlayerSide.blue ? const Color(0xFF1E2633) : const Color(0xFF2B2024);
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
    } else if (inDeployZone) {
      border = Border.all(
        color: currentSide == PlayerSide.blue ? const Color(0x556EA8FF) : const Color(0x55FF7B7B),
        width: 1.0,
      );
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
