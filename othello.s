########################################################################
#
# This program was written by Scott Tredinnick (z5258051)
# on 19/03/2023
#
# Play a game of othello where the player gets to decide the board size
# Every turn they get shown the board including possible moves
# If a player doesnt have a legal move the turn goes to the other player
# The game ends when all cells are filled or there are no more legal moves
# At the end a winner is announced and the scores are tallied
#
########################################################################

#![tabsize(8)]

# Bools
TRUE  = 1
FALSE = 0

# Players
PLAYER_EMPTY = 0
PLAYER_BLACK = 1
PLAYER_WHITE = 2

# Character shown when rendering board
WHITE_CHAR         = 'W'
BLACK_CHAR         = 'B'
POSSIBLE_MOVE_CHAR = 'x'
EMPTY_CELL_CHAR    = '.'

# Smallest and largest possible board sizes (standard Othello board size is 8)
MIN_BOARD_SIZE = 4
MAX_BOARD_SIZE = 12

# There are 8 directions a capture line can have (2 vertical, 2 horizontal and 4 diagonal).
NUM_DIRECTIONS = 8

# Some constants for accessing vectors
VECTOR_ROW_OFFSET = 0
VECTOR_COL_OFFSET = 4
SIZEOF_VECTOR     = 8


########################################################################
# DATA SEGMENT
	.data
	.align 2

# The actual board size, selected by the player
board_size:		.space 4

# Who's turn it is - either PLAYER_BLACK or PLAYER_WHITE
current_player:		.word PLAYER_BLACK

# The contents of the board
board:			.space MAX_BOARD_SIZE * MAX_BOARD_SIZE

# The 8 directions which a line can have when capturing
directions:
	.word	-1, -1  # Up left
	.word	-1,  0  # Up
	.word	-1,  1  # Up right
	.word	 0, -1  # Left
	.word	 0,  1  # Right
	.word	 1, -1  # Down left
	.word	 1,  0  # Down
	.word	 1,  1  # Down right

welcome_to_reversi_str:		.asciiz "Welcome to Reversi!\n"
board_size_prompt_str:		.asciiz "How big do you want the board to be? "
wrong_board_size_str_1:		.asciiz "Board size must be between "
wrong_board_size_str_2:		.asciiz " and "
wrong_board_size_str_3:		.asciiz "\n"
board_size_must_be_even_str:	.asciiz "Board size must be even!\n"
board_size_ok_str:		.asciiz "OK, the board size is "
white_won_str:			.asciiz "The game is a win for WHITE!\n"
black_won_str:			.asciiz "The game is a win for BLACK!\n"
tie_str:			.asciiz "The game is a tie! Wow!\n"
final_score_str_1:		.asciiz	"Score for black: "
final_score_str_2:		.asciiz ", for white: "
final_score_str_3:		.asciiz ".\n"
whos_turn_str_1:		.asciiz "\nIt is "
whos_turn_str_2:		.asciiz "'s turn.\n"
no_valid_move_str_1:		.asciiz "There are no valid moves for "
no_valid_move_str_2:		.asciiz "!\n"
game_over_str_1:		.asciiz "There are also no valid moves for "
game_over_str_2:		.asciiz "...\nGame over!\n"
enter_move_str:			.asciiz "Enter move (e.g. A 1): "
invalid_row_str:		.asciiz "Invalid row!\n"
invalid_column_str:		.asciiz "Invalid column!\n"
invalid_move_str:		.asciiz "Invalid move!\n"
white_str:			.asciiz "white"
black_str:			.asciiz "black"
board_str:			.asciiz "Board:\n   "

################################################################################
# .TEXT <main>
	.text
main:
	# Args:     void
	#
	# Returns:
	#    - $v0: int
	#
	# Frame:    [$ra]
	# Uses:     [$a0, $v0]
	# Clobbers: [$a0, $v0]
	#
	# Locals:
	#
	# Structure:
	#   main
	#   -> [prologue]
	#       -> body
	#   -> [epilogue]

main__prologue:
	begin
	push 	$ra

main__body:
	li 	$v0, 4				# printf("Welcome to Reversi!\n");
	la 	$a0, welcome_to_reversi_str	# 
	syscall 				# 

	jal 	read_board_size;		# read_board_size();

	jal 	initialise_board;		# initialise_board();

	jal 	place_initial_pieces;		# place_initial_pieces();

	jal  	play_game;			# play_game();

main__epilogue:
	pop 	$ra
	end

	li 	$v0, 0
	jr	$ra				# return;


################################################################################
# .TEXT <read_board_size>
	.text
# Get player input for the board size, must be between 4 and 12 and even
read_board_size:
	# Args:     void
	#
	# Returns:  void
	#
	# Frame:    [$ra]
	# Uses:     [$t0, $t1, $a0, $v0]
	# Clobbers: [$t0, $t1, $a0, $v0]
	#
	# Locals:
	#   - $t0: board_size
	#   - $t1: board_size % 2
	#
	# Structure:
	#   read_board_size
	#   -> [prologue]
	#       -> body
	#           -> ok
	#           -> incorrect
	#           -> even
	#   -> [epilogue]

read_board_size__prologue:
	begin
	push 	$ra

read_board_size__body:						# printf("How big do you want the board to be? ");
	li 	$v0, 4						#
	la 	$a0, board_size_prompt_str			#
	syscall						

	li 	$v0, 5						# scanf("%d", &board_size);
	syscall							#
	move 	$t0, $v0					#

	blt 	$t0, MIN_BOARD_SIZE, read_board_size__incorrect	# if (board_size < MIN_BOARD_SIZE || board_size > MAX_BOARD_SIZE)
	bgt	$t0, MAX_BOARD_SIZE, read_board_size__incorrect	# 

	rem 	$t1, $t0, 2					# int is_board_size_odd = board_size % 2;

	beq	$t1, 1, read_board_size__even			# if (board_size % 2 != 0)

read_board_size__ok:
	li 	$v0, 4						# printf("OK, the board size is ");
	la 	$a0, board_size_ok_str				#
	syscall							#

	li 	$v0, 1						# printf("%d", board_size);
	move 	$a0, $t0					#
	syscall							#

	li 	$v0, 11						# printf("\n");
	la 	$a0, '\n'					#
	syscall							#

	sw	$t0, board_size;				

	b	read_board_size__epilogue			# goto read_board_size__epilogue;

read_board_size__incorrect:
	li 	$v0, 4						# printf("Board size must be between ");
	la 	$a0, wrong_board_size_str_1			# 
	syscall							# 

	li 	$v0, 1						# printf("%d", MIN_BOARD_SIZE);
	li 	$a0, MIN_BOARD_SIZE				# 
	syscall							# 

	li 	$v0, 4						# printf(" and ");
	la 	$a0, wrong_board_size_str_2			# 
	syscall							# 

	li 	$v0, 1						# printf("%d", MAX_BOARD_SIZE);
	li 	$a0, MAX_BOARD_SIZE				# 
	syscall							# 

	li 	$v0, 4						# printf("\n");
	la 	$a0, wrong_board_size_str_3			# 
	syscall							# 

	b	read_board_size__body				# goto read_board_size__body;

read_board_size__even:
	li 	$v0, 4						# printf("Board size must be even!\n");
	la 	$a0, board_size_must_be_even_str		# 
	syscall							# 

	b	read_board_size__body				# goto read_board_size__body;

read_board_size__epilogue:
	pop 	$ra
	end
	jr	$ra						# return;


################################################################################
# .TEXT <initialise_board>
	.text
# Based on the given board size set every cell on the board to empty
initialise_board:
	# Args:     void
	#
	# Returns:  void
	#
	# Frame:    [$ra]
	# Uses:     [$t0, $t1, $t2, $t3, $t4]
	# Clobbers: [$t0, $t1, $t2, $t3, $t4]
	#
	# Locals:
	#   - $t0: row
	#   - $t1: col
	#   - $t2: board_size
	#   - $t3: board[row][col]
	#   - $t4: PLAYER_EMPTY
	#
	# Structure:
	#   initialise_board
	#   -> [prologue]
	#       -> body
	#           -> row
	#           -> cell
	#   -> [epilogue]

initialise_board__prologue:
	begin
	push 	$ra

initialise_board__body:
	li 	$t0, 0					# int row = 0;
	li 	$t1, 0					# int col = 0;
	lw 	$t2, board_size				

initialise_board__row:
	bge 	$t0, $t2, initialise_board__epilogue	# if (row >= board_size) goto initialise_board__epilogue;

initialise_board__cell:
	mul	$t3, $t0, MAX_BOARD_SIZE		# &board[row][col] = row * MAX_BOARD_SIZE
	add	$t3, $t3, $t1				# 	+ col

	li 	$t4, PLAYER_EMPTY			

	sb 	$t4, board($t3)				# board[row][col] = PLAYER_EMPTY; (This also adds the position of board)

	addi 	$t1, $t1, 1				# col = col + 1;
	blt 	$t1, $t2, initialise_board__cell	# if (col < board_size) goto initialise_board__cell;
	li 	$t1, 0					# col = 0;
	addi 	$t0, $t0, 1				# row = row + 1;
	b 	initialise_board__row			# goto initialise_board__row;

initialise_board__epilogue:
	pop 	$ra
	end
	jr	$ra					# return;


################################################################################
# .TEXT <place_initial_pieces>
	.text
# Place the initial four pieces in the centre square of the board in an alternating pattern
place_initial_pieces:
	# Args:     void
	#
	# Returns:  void
	#
	# Frame:    [$ra]
	# Uses:     [$t0, $t1, $t2, $t3, $t4]
	# Clobbers: [$t0, $t1, $t2, $t3, $t4]
	#
	# Locals:
	#   - $t0: board_size
	#   - $t1: board_size / 2
	#   - $t2: board_size / 2 - 1
	#   - $t3: &board[row][col] (General board positioning)
	#   - $t4: PLAYER_WHITE, PLAYER_BLACK
	#
	# Structure:
	#   place_initial_pieces
	#   -> [prologue]
	#       -> body
	#   -> [epilogue]

place_initial_pieces__prologue:
	begin
	push 	$ra

place_initial_pieces__body:
	lw 	$t0, board_size
	div 	$t1, $t0, 2				# int half_board = board_size / 2
	sub	$t2, $t1, 1				# int half_board_less_one = half_board - 1

	mul	$t3, $t2, MAX_BOARD_SIZE		# &board[half_board_less_one][half_board_less_one] = half_board_less_one * MAX_BOARD_SIZE
	add	$t3, $t3, $t2				# 	+ half_board_less_one

	li 	$t4, PLAYER_WHITE
	sb 	$t4, board($t3)				# board[half_board_less_one][half_board_less_one] = PLAYER_WHITE

	mul	$t3, $t1, MAX_BOARD_SIZE		# &board[half_board][half_board] = half_board * MAX_BOARD_SIZE
	add	$t3, $t3, $t1				# 	+ half_board	

	sb 	$t4, board($t3)				# board[half_board][half_board] = PLAYER_WHITE

	mul	$t3, $t1, MAX_BOARD_SIZE		# &board[half_board][half_board_less_one] = half_board * MAX_BOARD_SIZE
	add	$t3, $t3, $t2				# 	+ half_board_less_one

	li 	$t4, PLAYER_BLACK
	sb 	$t4, board($t3)				# board[half_board][half_board_less_one] = PLAYER_BLACK

	mul	$t3, $t2, MAX_BOARD_SIZE		# &board[half_board_less_one][half_board] = half_board_less_one * MAX_BOARD_SIZE
	add	$t3, $t3, $t1				# 	+ half_board

	sb 	$t4, board($t3)				# board[half_board_less_one][half_board] = PLAYER_BLACK

place_initial_pieces__epilogue:
	pop 	$ra
	end
	jr	$ra					# return;


################################################################################
# .TEXT <play_game>
	.text
# Start playing the game
play_game:
	# Args:     void
	#
	# Returns:  void
	#
	# Frame:    [$ra]
	# Uses:     [$v0]
	# Clobbers: [$v0]
	#
	# Locals:
	#
	# Structure:
	#   play_game
	#   -> [prologue]
	#       -> body
	#   -> [epilogue]

play_game__prologue:
	begin
	push 	$ra

play_game__body:
	jal 	play_turn			# while (play_turn());
	beq	$v0, 1, play_game__body		#

	jal 	announce_winner			# announce_winner();

play_game__epilogue:
	pop 	$ra
	end
	jr	$ra				# return;


################################################################################
# .TEXT <announce_winner>
	.text
# Announce a winner and the score at the end of the game
# The winner also gets all the empty spaces added to their score
announce_winner:
	# Args:     void
	#
	# Returns:  void
	#
	# Frame:    [$ra, $s0, $s1, $s2]
	# Uses:     [$s0, $s1, $s2, $a0, $v0]
	# Clobbers: [$a0, $v0]
	#
	# Locals:
	#   - $s0: black_count
	#   - $s1: white_count
	#   - $s2: empty_count
	#
	# Structure:
	#   announce_winner
	#   -> [prologue]
	#       -> body
	#           -> black
	#           -> white
	#           -> score
	#   -> [epilogue]

announce_winner__prologue:
	begin
	push 	$ra
	push 	$s0
	push 	$s1
	push 	$s2

announce_winner__body:
	li 	$a0, PLAYER_BLACK			# int black_count = count_discs(PLAYER_BLACK);
	jal 	count_discs				# 
	move 	$s0, $v0				# 

	li 	$a0, PLAYER_WHITE			# int white_count = count_discs(PLAYER_WHITE);
	jal 	count_discs				# 
	move 	$s1, $v0				# 

	bgt 	$s0, $s1, announce_winner__black	# if (black_count > white_count) goto announce_winner__black;
	bgt 	$s1, $s0, announce_winner__white	# if (white_count > black_count) goto announce_winner__white;

	li 	$v0, 4					# printf("The game is a tie! Wow!\n");
	la 	$a0, tie_str				# 
	syscall						# 
	b 	announce_winner__score			# goto announce_winner__score;

announce_winner__black:
	li 	$v0, 4					# printf("The game is a win for BLACK!\n");
	la 	$a0, black_won_str			# 
	syscall						# 

	li 	$a0, PLAYER_EMPTY			# int empty_count = count_discs(PLAYER_EMPTY);
	jal 	count_discs				# 
	move  	$s2, $v0				# 

	add 	$s0, $s0, $s2				# black_count = black_count + empty_count;
	b 	announce_winner__score			# goto announce_winner__score;

announce_winner__white:
	li 	$v0, 4					# printf("The game is a win for WHITE!\n");
	la 	$a0, white_won_str			# 
	syscall						# 

	li 	$a0, PLAYER_EMPTY			# int empty_count = count_discs(PLAYER_EMPTY);
	jal 	count_discs				# 
	move  	$s2, $v0				# 

	add 	$s1, $s1, $s2				# white_count = white_count + empty_count;
	b 	announce_winner__score			# goto announce_winner__score;

announce_winner__score:
	li 	$v0, 4					# printf("Score for black: ");
	la 	$a0, final_score_str_1			# 
	syscall						# 

	li 	$v0, 1					# printf("%d", black_count);
	move	$a0, $s0				# 
	syscall						# 

	li 	$v0, 4					# printf(", for white: ");
	la 	$a0, final_score_str_2			# 
	syscall						# 

	li 	$v0, 1					# printf("%d", white_count);
	move	$a0, $s1				# 
	syscall						# 

	li 	$v0, 4					# printf("\n");
	la 	$a0, final_score_str_3			# 
	syscall						# 

announce_winner__epilogue:
	pop 	$s2
	pop 	$s1
	pop 	$s0
	pop 	$ra
	end
	jr	$ra					# return;


################################################################################
# .TEXT <count_discs>
	.text
# Count the amount of discs a player has
count_discs:
	# Args:
	#    - $a0: int player
	#
	# Returns:
	#    - $v0: unsigned int
	#
	# Frame:    [$ra]
	# Uses:     [$t0, $t1, $t2, $t3, $t4, $t5, $a0, $v0]
	# Clobbers: [$t0, $t1, $t2, $t3, $t4, $t5, $a0, $v0]
	#
	# Locals:
	#   - $t0: count
	#   - $t1: row
	#   - $t2: col
	#   - $t3: board_size
	#   - $t4: &board[row][col]
	#   - $t5: board[row][col]
	#
	# Structure:
	#   count_discs
	#   -> [prologue]
	#       -> body
	#           -> row
	#           -> cell
	#           -> next
	#           -> increase
	#   -> [epilogue]

count_discs__prologue:
	begin
	push 	$ra

count_discs__body:
	li 	$t0, 0					# int count = 0;
	li 	$t1, 0					# int row = 0;
	li 	$t2, 0					# int col = 0;
	lw 	$t3, board_size

count_discs__row:
	bge 	$t1, $t3, count_discs__epilogue		# if (row >= board_size) goto count_discs__epilogue;

count_discs__cell:
	mul	$t4, $t1, MAX_BOARD_SIZE		# &board[row][col] = row * MAX_BOARD_SIZE
	add	$t4, $t4, $t2				# 	+ col
	lb 	$t5, board($t4)				

	beq 	$t5, $a0, count_discs__increase		# if (board[row][col] == player) goto count_discs__increase;

count_discs__next:
	addi 	$t2, $t2, 1				# col = col + 1;
	blt	$t2, $t3, count_discs__cell		# if (col < board_size) goto count_discs__cell;
	li 	$t2, 0					# col = 0;
	addi 	$t1, $t1, 1				# row = row + 1;
	b	count_discs__row			# goto count_discs__row;
	
count_discs__increase:
	addi 	$t0, $t0, 1				# count = count + 1;
	b 	count_discs__next			# goto count_discs__next;

count_discs__epilogue:
	move 	$v0, $t0				# return count; (Just setting up to return the value)

	pop 	$ra
	end
	jr	$ra					# return; 


################################################################################
# .TEXT <play_turn>
	.text
# Play a single turn of othello
play_turn:
	# Args:     void
	#
	# Returns:
	#    - $v0: int
	#
	# Frame:    [$ra, $s0, $s1, $s2]
	# Uses:     [$s0, $s1, $s2, $a0, $a1, $v0]
	# Clobbers: [$a0, $a1, $v0]
	#
	# Locals:
	#   - $s0: move_col_letter, move_col
	#   - $s1: move_row
	#   - $s2: board_size
	#
	# Structure:
	#   play_turn
	#   -> [prologue]
	#       -> body
	#           -> none
	#           -> next
	#           -> valid
	#           -> inv_row
	#           -> inv_col
	#           -> inv_move
	#   -> [epilogue]

play_turn__prologue:
	begin
	push 	$ra
	push 	$s0
	push 	$s1
	push 	$s2

play_turn__body:
	li 	$v0, 4				# printf("\nIt is ");
	la 	$a0, whos_turn_str_1		# 
	syscall					# 

	jal 	current_player_str		# printf("%s", current_player_str());
	move 	$a0, $v0			# 
	li 	$v0, 4				# 
	syscall					# 

	la 	$a0, whos_turn_str_2		# printf("'s turn.\n");
	syscall					# 

	jal 	print_board			# print_board();

	jal	player_has_a_valid_move		# if (player_has_a_valid_move() == TRUE) goto play_turn__next;
	beq 	$v0, 1, play_turn__next		# 

	li 	$v0, 4				# printf("There are no valid moves for ");
	la	$a0, no_valid_move_str_1	# 
	syscall					# 

	jal 	current_player_str		# printf("%s", current_player_str());
	move 	$a0, $v0			# 
	li 	$v0, 4				# 
	syscall					# 

	li 	$v0, 4				# printf("!\n");
	la	$a0, no_valid_move_str_2	# 
	syscall					# 

	jal 	other_player			# current_player = other_player();
	sw 	$v0, current_player		# 

	jal	player_has_a_valid_move		# if (player_has_a_valid_move() == FALSE) goto play_turn__none;
	beqz 	$v0, play_turn__none		# 
	li 	$v0, TRUE			# return TRUE; (Set up return value)
	b	play_turn__epilogue		# 

play_turn__none:
	li 	$v0, 4				# printf("There are also no valid moves for ");
	la 	$a0, game_over_str_1		# 
	syscall					# 

	jal 	current_player_str		# printf("%s", current_player_str());
	move 	$a0, $v0			# 
	li 	$v0, 4				# 
	syscall					# 

	li 	$v0, 4				# printf("...\nGame over!\n");
	la 	$a0, game_over_str_2		# 
	syscall					# 

	li 	$v0, FALSE			# return FALSE; (Set up return value)
	b 	play_turn__epilogue		# 

play_turn__next:
	li 	$v0, 4				# rintf("Enter move (e.g. A 1): ");
	la 	$a0, enter_move_str		# 
	syscall					# 

	li 	$v0, 12				# scanf(" %c", &move_col_letter);
	syscall					# 
	move 	$s0, $v0			# 

	li 	$v0, 5				# scanf("%d", &move_row);
	syscall 				# 
	move 	$s1, $v0			# 

	sub 	$s1, $s1, 1			# move_row = move_row - 1;

	sub 	$s0, $s0, 'A'			# int move_col = move_col_letter - 'A';

	lw 	$s2, board_size			# 

	bltz 	$s1, play_turn__inv_row		# if (move_row < 0) goto play_turn__inv_row;
	bge 	$s1, $s2, play_turn__inv_row	# if (move_row >= board_size) goto play_turn__inv_row

	bltz 	$s0, play_turn__inv_col		# if (move_col < 0) goto play_turn__inv_col;
	bge 	$s0, $s2, play_turn__inv_col	# if (move_col >= board_size) goto play_turn__inv_col;

	move 	$a0, $s1			# if (is_valid_move(move_row, move_col) == FALSE) goto play_turn__inv_move;
	move  	$a1, $s0			# 
	jal 	is_valid_move			# 
	beqz	$v0, play_turn__inv_move	# 

play_turn__valid:
	move 	$a0, $s1			# place_move(move_row, move_col);
	move  	$a1, $s0			# 
	jal 	place_move			# 

	jal 	other_player			# current_player = other_player();
	sw 	$v0, current_player		# 
	li 	$v0, TRUE			# return TRUE;
	b 	play_turn__epilogue		# 

play_turn__inv_row:
	li 	$v0, 4				# printf("Invalid row!\n");
	la 	$a0, invalid_row_str		# 
	syscall					# 

	li 	$v0, TRUE			# return TRUE;
	b 	play_turn__epilogue		# 

play_turn__inv_col:
	li 	$v0, 4				# printf("Invalid column!\n");
	la 	$a0, invalid_column_str		# 
	syscall					# 

	li 	$v0, TRUE			# return TRUE;
	b 	play_turn__epilogue		# 

play_turn__inv_move:
	li 	$v0, 4				# printf("Invalid move!\n");
	la 	$a0, invalid_move_str		# 
	syscall					# 

	li 	$v0, TRUE			# return TRUE;

play_turn__epilogue:
	pop 	$s2
	pop 	$s1
	pop 	$s0
	pop 	$ra
	end
	jr	$ra				# return;


################################################################################
# .TEXT <place_move>
	.text
# Place a tile on the board
place_move:
	# Args:
	#    - $a0: int row
	#    - $a1: int col
	#
	# Returns:  void
	#
	# Frame:    [$ra, $s0, $s1, $s2, $s3]
	# Uses:     [$t0, $t1, $t2, $t3, $t4, $5, $t6, $s0, $s1, $s2, $s3 $a0, $a1, $a2 $v0]
	# Clobbers: [$t0, $t1, $t2, $t3, $t4, $5, $t6, $a0, $a1, $a2, $v0]
	#
	# Locals:
	#   - $s0: direction
	#   - $s1: *delta
	#   - $s2: $a0 storage
	#   - $s3: $a1 storage
	#   - $t0: &directions[direction]
	#   - $t1: capture_amt
	#   - $t2: i
	#   - $t3: delta->row, i_row, row (differnt from the arguement)
	#   - $t4: delta->col, i_col, col (differnt from the arguement)
	#   - $t5: &board[row][col]
	#   - $t6: board[row][col]
	#
	# Structure:
	#   place_move
	#   -> [prologue]
	#       -> body
	#           -> direction
	#           -> capture
	#           -> change
	#   -> [epilogue]

place_move__prologue:
	begin
	push 	$ra
	push 	$s0
	push 	$s1
	push 	$s2
	push 	$s3

place_move__body:
	li 	$s0, 0						# int direction = 0;
	move 	$s2, $a0		
	move 	$s3, $a1

place_move__direction:
	bge 	$s0, NUM_DIRECTIONS, place_move__epilogue	# if (direction >= NUM_DIRECTIONS) goto place_move__epilogue;

	mul 	$t0, $s0, 8					# const vector *delta = &directions[direction];
	addi 	$s1, $t0, directions				# 

	move 	$a0, $s2					# int capture_amt = capture_amount_from_direction(move_row, move_col, delta);
	move 	$a1, $s3					# 
	move 	$a2, $s1					# 
	jal 	capture_amount_from_direction			# 
	move 	$t1, $v0					# 

	li 	$t2, 0						# int i = 0;

place_move__capture:
	bgt 	$t2, $t1, place_move__change			# if (i > capture_amt) goto place_move__change;

	lw 	$t3, ($s1)					# delta->row
	lw 	$t4, 4($s1)					# delta->col

	mul 	$t3, $t3, $t2					# int i_row = i * delta->row;
	mul 	$t4, $t4, $t2					# int i_col = i * delta->col;

	add 	$t3, $t3, $s2					# int row = move_row + i_row;
	add 	$t4, $t4, $s3					# int col = move_col + i_col;

	mul	$t5, $t3, MAX_BOARD_SIZE			# &board[row][col] = row * MAX_BOARD_SIZE
	add	$t5, $t5, $t4					# 	+ col

	lb 	$t6, current_player				# board[row][col] = current_player;
	sb	$t6, board($t5)					# 

	addi 	$t2, $t2, 1					# i = i + 1;

	b 	place_move__capture				# goto place_move__capture;

place_move__change:
	addi 	$s0, $s0, 1					# direction = direction + 1;
	b 	place_move__direction 				# goto place_move__direction;

place_move__epilogue:
	pop 	$s3
	pop 	$s2
	pop 	$s1
	pop 	$s0
	pop 	$ra
	end
	jr	$ra						# return;


################################################################################
# .TEXT <player_has_a_valid_move>
	.text
# Check if a player has a legal move available to them
player_has_a_valid_move:
	# Args:     void
	#
	# Returns:
	#    - $v0: int
	#
	# Frame:    [$ra, $s0, $s1, $s2, $s3]
	# Uses:     [$s0, $s1, $s2, $s3, $a0, $a1, $v0]
	# Clobbers: [$a0, $a1, $v0]
	#
	# Locals:
	#   - $s0: row
	#   - $s1: col
	#   - $s2: board_size
	#   - $s3: TRUE, FALSE
	#
	# Structure:
	#   player_has_a_valid_move
	#   -> [prologue]
	#       -> body
	#           -> row
	#           -> check
	#           -> true
	#   -> [epilogue]

player_has_a_valid_move__prologue:
	begin
	push 	$ra
	push 	$s0
	push 	$s1
	push 	$s2
	push 	$s3

player_has_a_valid_move__body:
	li 	$s0, 0						# int row = 0;
	li 	$s1, 0						# int col = 0;
	lw 	$s2, board_size					
	li 	$s3, FALSE					# set return value to FALSE

player_has_a_valid_move__row:
	bge 	$s0, $s2, player_has_a_valid_move__epilogue	# if (row >= board_size) goto player_has_a_valid_move__epilogue;

player_has_a_valid_move__check:
	move 	$a0, $s0					# int valid_move = is_valid_move(row, col)
	move 	$a1, $s1					# 
	jal 	is_valid_move					# 
	beq 	$v0, 1, player_has_a_valid_move__true		# if (valid_move) goto player_has_a_valid_move__true;

	addi 	$s1, $s1, 1					# col = col + 1;
	blt 	$s1, $s2, player_has_a_valid_move__check	# if (col < board_size) player_has_a_valid_move__check;

	li 	$s1, 0						# col = 0;
	addi 	$s0, $s0, 1					# row = row + 1;
	b 	player_has_a_valid_move__row			# goto player_has_a_valid_move__row;

player_has_a_valid_move__true:
	li 	$s3, TRUE					# set return value to TRUE

player_has_a_valid_move__epilogue:
	move 	$v0, $s3					# return TRUE or FALSE (Depending on previous code)

	pop 	$s3
	pop 	$s2
	pop 	$s1
	pop 	$s0
	pop 	$ra
	end
	jr	$ra						# return;


################################################################################
# .TEXT <is_valid_move>
	.text
# Check if an individual cell would be a valid move for the current player
is_valid_move:
	# Args:
	#    - $a0: int row
	#    - $a1: int col
	#
	# Returns:
	#    - $v0: int
	#
	# Frame:    [$ra, $s0, $s1, $s2, $s3]
	# Uses:     [$t0, $t1, $s0, $s1, $s2, $s3, $a0, $a1, $a2, $v0]
	# Clobbers: [$t0, $t1, $a0, $a1, $a2, $v0]
	#
	# Locals:
	#   - $t0: &board[row][col]
	#   - $t1: board[row][col]
	#   - $s0: $a0 storage
	#   - $s1: $a1 storage
	#   - $s2: direction
	#   - $s3: TRUE, FALSE	
	#
	# Structure:
	#   is_valid_move
	#   -> [prologue]
	#       -> body
	#           -> direction
	#           -> true
	#   -> [epilogue]

is_valid_move__prologue:
	begin
	push 	$ra
	push 	$s0
	push 	$s1
	push 	$s2
	push 	$s3

is_valid_move__body:
	move 	$s0, $a0
	move 	$s1, $a1
	li 	$s3, FALSE					# set return value to FALSE

	mul	$t0, $s0, MAX_BOARD_SIZE			# &board[row][col] = row * MAX_BOARD_SIZE
	add	$t0, $t0, $s1					# 	+ col

	lb 	$t1, board($t0)					# int current_cell = board[row][col]

	bne 	$t1, PLAYER_EMPTY, is_valid_move__epilogue	# if (current_cell != PLAYER_EMPTY) goto is_valid_move__epilogue;

	li 	$s2, 0						# int direction = 0;

is_valid_move__direction:
	bge 	$s2, NUM_DIRECTIONS, is_valid_move__epilogue	# if (direction >= NUM_DIRECTIONS) goto is_valid_move__epilogue;

	mul 	$t3, $s2, 8					# const vector *delta = &directions[direction];
	addi 	$t3, $t3, directions				# 

	move 	$a0, $s0					# int cap_amt = capture_amount_from_direction(row, col, &directions[direction])
	move 	$a1, $s1					# 
	move 	$a2, $t3					# 
	jal 	capture_amount_from_direction			# 
	bgtz	$v0, is_valid_move__true			# if (cap_amt > 0) goto is_valid_move__true;

	addi 	$s2, $s2, 1					# direction = direction + 1;
	b 	is_valid_move__direction			# goto is_valid_move__direction;

is_valid_move__true:
	li 	$s3, TRUE					# set return value to TRUE

is_valid_move__epilogue:
	move 	$v0, $s3					
	
	pop 	$s3
	pop 	$s2
	pop 	$s1
	pop 	$s0
	pop 	$ra
	end
	jr	$ra						# return TRUE or FALSE;


################################################################################
# .TEXT <capture_amount_from_direction>
	.text
# Determine the amount of pieces to be captured in every direction around a cell
capture_amount_from_direction:
	# Args:
	#    - $a0: int row
	#    - $a1: int col
	#    - $a2: const vector *delta
	#
	# Returns:
	#    - $v0: unsigned int
	#
	# Frame:    [$ra, $s0, $s1, $s2, $s3]
	# Uses:     [$s0, $s1, $s2, $s3, $t2, $t3, $t4, $t5, $t6, $t7, $t8, $t9, $a0, $a1, $a2, $v0]
	# Clobbers: [$t2, $t3, $t4, $t5, $t6, $t7, $t8, $t9, $a0, $a1, $a2, $v0]
	#
	# Locals:
	#   - $s0: $a0 storage 
	#   - $s1: $a1 storage
	#   - $s2: $a2 storage
	#   - $s3: board_size
	#   - $t2: other_player
	#   - $t3: line_length
	#   - $t4: delta->row
	#   - $t5: delta->col
	#   - $t6: board_size
	#   - $t7: &board[row][col]
	#   - $t8: board[row][col]
	#   - $t9: current_player
	#
	# Structure:
	#   capture_amount_from_direction
	#   -> [prologue]
	#       -> body
	#           -> loop
	#           -> valid
	#           -> zero
	#   -> [epilogue]

capture_amount_from_direction__prologue:
	begin
	push 	$ra
	push 	$s0
	push 	$s1
	push 	$s2
	push 	$s3

capture_amount_from_direction__body:
	move 	$s0, $a0					
	move 	$s1, $a1					
	move 	$s2, $a2					
	lw 	$s3, board_size					
	
	jal 	other_player					# int opposite = other_player();
	move 	$t2, $v0					# 

	li 	$t3, 0						# int line_length = 0;

capture_amount_from_direction__loop:
	lw 	$t4, ($s2)					# delta->row
	lw 	$t5, 4($s2)					# delta->col

	add 	$s0, $s0, $t4					# row = row + delta->row;
	add 	$s1, $s1, $t5					# col = col + delta->col;

	bltz 	$s0, capture_amount_from_direction__zero	# if (row < 0) goto capture_amount_from_direction__zero;
	bge 	$s0, $s3, capture_amount_from_direction__zero	# if (row >= board_size) goto capture_amount_from_direction__zero;

	bltz 	$s1, capture_amount_from_direction__zero	# if (col < 0) goto capture_amount_from_direction__zero;
	bge 	$s1, $s3, capture_amount_from_direction__zero	# if (col >= board_size) goto capture_amount_from_direction__zero;

	mul	$t7, $s0, MAX_BOARD_SIZE			# &board[row][col] = row * MAX_BOARD_SIZE
	add	$t7, $t7, $s1					# 	+ col
	lb 	$t8, board($t7)					# 

	bne 	$t8, $t2, capture_amount_from_direction__valid	# if (board[row][col] != opposite) goto capture_amount_from_direction__valid;

	addi 	$t3, $t3, 1					# line_length = line_length + 1;
	b 	capture_amount_from_direction__loop		# goto capture_amount_from_direction__loop;

capture_amount_from_direction__valid:
	lw 	$t9, current_player				# if (board[row][col] != current_player) goto zero_capture;
	bne 	$t8, $t9, capture_amount_from_direction__zero	# 
	move 	$v0, $t3					# return line_length; (set return value)
	b 	capture_amount_from_direction__epilogue		# 

capture_amount_from_direction__zero:
	li 	$v0, 0						# return 0;

capture_amount_from_direction__epilogue:
	pop 	$s3		
	pop 	$s2
	pop 	$s1
	pop 	$s0
	pop 	$ra
	end
	jr	$ra						# return;


################################################################################
# .TEXT <other_player>
	.text
# Which player is not playing this turn
other_player:
	# Args:     void
	#
	# Returns:
	#    - $v0: int
	#
	# Frame:    [$ra]
	# Uses:     [$t0, $t1, $v0]
	# Clobbers: [$t0, $t1, $v0]
	#
	# Locals:
	#   - $t0: current_player
	#   - $t1: PLAYER_BLACK
	#
	# Structure:
	#   other_player
	#   -> [prologue]
	#       -> body
	#           -> black
	#           -> white
	#   -> [epilogue]

other_player__prologue:
	begin
	push 	$ra

other_player__body:
	lw 	$t0, current_player
	li 	$t1, PLAYER_BLACK

	beq 	$t0, $t1, other_player__white	# if (current_player == PLAYER_BLACK) goto other_player__white;

other_player__black:
	li 	$v0, PLAYER_BLACK		# return PLAYER_BLACK; (Set up return value)
	b	other_player__epilogue		# goto other_player__epilogue;

other_player__white:
	li 	$v0, PLAYER_WHITE		# return PLAYER_WHITE; (Set up return value)

other_player__epilogue:
	pop 	$ra
	end
	jr	$ra				# return;


################################################################################
# .TEXT <current_player_str>
	.text
# Which player is currently playing this turn
current_player_str:
	# Args:     void
	#
	# Returns:
	#    - $v0: const char *
	#
	# Frame:    [$ra]
	# Uses:     [$t0, $t1, $v0]
	# Clobbers: [$t0, $t1, $v0]
	#
	# Locals:
	#   - $t0: current_player
	#   - $t1: PLAYER_BLACK
	#
	# Structure:
	#   current_player_str
	#   -> [prologue]
	#       -> body
	#           -> white
	#           -> black
	#   -> [epilogue]

current_player_str__prologue:
	begin
	push 	$ra

current_player_str__body:
	lw 	$t0, current_player			
	li 	$t1, PLAYER_BLACK			

	beq 	$t0, $t1, current_player_str__black	# if (current_player == PLAYER_BLACK) goto current_player_str__black;

current_player_str__white:
	la 	$v0, white_str				# return "black";(Set up return value)
	b	current_player_str__epilogue		# 

current_player_str__black:
	la 	$v0, black_str				# return "white";(Set up return value)

current_player_str__epilogue:
	pop 	$ra
	end
	jr	$ra					# return;


################################################################################
################################################################################
###                    PROVIDED FUNCTION — DO NOT CHANGE                     ###
################################################################################
################################################################################

################################################################################
# .TEXT <print_board>
# YOU DO NOT NEED TO CHANGE THE print_board FUNCTION
	.text
print_board:
	# Args: void
	#
	# Returns:  void
	#
	# Frame:    [$ra, $s0, $s1]
	# Uses:     [$a0, $v0, $t2, $t3, $t4, $s0, $s1]
	# Clobbers: [$a0, $v0, $t2, $t3, $t4]
	#
	# Locals:
	#   - $s0: col
	#   - $s1: row
	#   - $t2: board_size, row + 1
	#   - $t3: &board[row][col]
	#   - $t4: board[row][col]
	#
	# Structure:
	#   print_board
	#   -> [prologue]
	#   -> body
	#      -> header_loop
	#      -> header_loop__init
	#      -> header_loop__cond
	#      -> header_loop__body
	#      -> header_loop__step
	#      -> header_loop__end
	#      -> for_row
	#      -> for_row__init
	#      -> for_row__cond
	#      -> for_row__body
	#          -> print_row_num
	#          -> for_col
	#          -> for_col__init
	#          -> for_col__cond
	#          -> for_col__body
	#              -> white
	#              -> black
	#              -> possible_move
	#              -> output_cell
	#          -> for_col__step
	#          -> for_col__end
	#      -> for_row__step
	#      -> for_row__end
	#   -> [epilogue]

print_board__prologue:
	begin
	push	$ra
	push	$s0
	push	$s1

print_board__body:
	li	$v0, 4
	la	$a0, board_str
	syscall						# printf("Board:\n   ");

print_board__header_loop:
print_board__header_loop__init:
	li	$s0, 0					# int col = 0;

print_board__header_loop__cond:
	lw	$s1, board_size
	bge	$s0, $s1, print_board__header_loop__end # while (col < board_size) {

print_board__header_loop__body:
	li	$v0, 11
	addi	$a0, $s0, 'A'
	syscall						#     printf("%c", 'A' + col);

	li	$a0, ' '
	syscall						#     putchar(' ');

print_board__header_loop__step:
	addi	$s0, $s0, 1				#     col++;
	b	print_board__header_loop__cond		# }

print_board__header_loop__end:
	li	$v0, 11
	li	$a0, '\n'
	syscall						# printf("\n");

print_board__for_row:
print_board__for_row__init:
	li	$s0, 0					# int row = 0;

print_board__for_row__cond:
	lw	$t2, board_size
	bge	$s0, $t2, print_board__for_row__end	# while (row < board_size) {

print_board__for_row__body:
	addi	$t2, $s0, 1
	bge	$t2, 10, print_board__print_row_num	#     if (row + 1 < 10) {

	li	$v0, 11
	li	$a0, ' '
	syscall						#         printf("%d ", row + 1);

print_board__print_row_num:				#     }
	li	$v0, 1
	move	$a0, $t2
	syscall						#     printf("%d", row + 1);

	li	$v0, 11
	li	$a0, ' '
	syscall						#     putchar(' ');

print_board__for_col:
print_board__for_col__init:
	li	$s1, 0					#     int col = 0;

print_board__for_col__cond:
	lw	$t2, board_size
	bge	$s1, $t2, print_board__for_col__end	#     while (col < board_size) {

print_board__for_col__body:
	mul	$t3, $s0, MAX_BOARD_SIZE		#         &board[row][col] = row * MAX_BOARD_SIZE
	add	$t3, $t3, $s1				#                            + col
	addi	$t3, board				#                            + &board

	lb	$t4, ($t3)				#         char cell = board[row][col];

	beq	$t4, PLAYER_WHITE, print_board__white	#         if (cell == PLAYER_WHITE) goto print_board__white;
	beq	$t4, PLAYER_BLACK, print_board__black	#         if (cell == PLAYER_BLACK) goto print_board__black;

	move	$a0, $s0
	move	$a1, $s1
	jal	is_valid_move
	bnez	$v0, print_board__possible_move		#         if (is_valid_move(row, col)) goto print_board__possible_move;

	li	$a0, EMPTY_CELL_CHAR			#         c = EMPTY_CELL_CHAR;
	b	print_board__output_cell		#         goto print_board__output_cell;

print_board__white:
	li	$a0, WHITE_CHAR				#         c = WHITE_CHAR;
	b	print_board__output_cell		#         goto print_board__output_cell;

print_board__black:
	li	$a0, BLACK_CHAR				#         c = BLACK_CHAR;
	b	print_board__output_cell		#         goto print_board__output_cell;

print_board__possible_move:
	li	$a0, POSSIBLE_MOVE_CHAR			#         c = POSSIBLE_MOVE_CHAR;
	b	print_board__output_cell		#         goto print_board__output_cell;

print_board__output_cell:
	li	$v0, 11
	syscall						#         printf("%c", c);

	li	$a0, ' '
	syscall						#         putchar(' ');

print_board__for_col__step:
	addi	$s1, $s1, 1				#         col++;
	b	print_board__for_col__cond		#     }

print_board__for_col__end:
	li	$v0, 11
	li	$a0, '\n'
	syscall						#     putchar('\n');

print_board__for_row__step:
	addi	$s0, $s0, 1				#     row++;
	b	print_board__for_row__cond		# }

print_board__for_row__end:
print_board__epilogue:
	pop	$s1
	pop	$s0
	pop	$ra
	end

	jr	$ra					# return;
