// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/// @title CoinFlipGame
/// @author Burtininkas69
/// @dev Creates a game lobby struct. Second player joining will trigger a coinflip.

contract CoinFlipGame {

    event NewGame(address _player1, uint256 _gamePrice);
    event SecondPlayerJoined(address _player2, uint256 _gamePrice);
    event WonTheGame(address _winner, uint256 _gamePrice);

    /// @notice Ether is used in creating game price. It let's user type value in ether, not wei.
    /// @dev This limits game floor price to 1 ether.
    uint256 Ether=1 ether;
    uint256 Randnonce=0;

    struct gameLobby {
        address player1;
        address player2;
        address winner;
        uint256 gamePrice;
        bool completed;
    }

    mapping(address=> uint) public Wins;
    mapping(address=> uint) public Losses; //pretty embarrassing, I know

    /// @notice Player will be able to easily check game lobby information.
    gameLobby[] public lobbyInfo;

    /// @notice Creates a struct with 1 player and set game price.
    /// @dev Minimum game price is 1 either because you can't type commas while interacting with smart contract. To change remove the first function line.
    function CreateGame(uint _price) public payable {
        uint gamePrice=Ether * _price;
        require(msg.value >=gamePrice, "Entered amount is lower than the set game price");
        gameLobby memory newGame=gameLobby(msg.sender, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000, gamePrice, false);
        lobbyInfo.push(newGame);
        emit NewGame(msg.sender, gamePrice);
    }

    /// @notice Player picks open gameID to join. After joining a coinflip will start and winner will be picked instantly.
    function JoinGame(uint _gameId) public payable {
        require(lobbyInfo[_gameId].completed==false, "Game is completed, Join another or Create your own");
        require(msg.sender !=lobbyInfo[_gameId].player1, "You can't play with yourself here");
        require(msg.value >=lobbyInfo[_gameId].gamePrice, "Entered amount is lower than the game price");
        lobbyInfo[_gameId].player2=msg.sender;
        emit SecondPlayerJoined(msg.sender, lobbyInfo[_gameId].gamePrice);
        StartGame(_gameId);
        emit WonTheGame(lobbyInfo[_gameId].winner, lobbyInfo[_gameId].gamePrice);
    }

    /// @notice Coinflip game will be called in JoinGame. Checks if generated number is under or over 50 mark.
    function StartGame(uint _gameId) internal {
        uint rand=randMod();

        if (rand < 50) {
            lobbyInfo[_gameId].winner=lobbyInfo[_gameId].player1;
            Wins[lobbyInfo[_gameId].player1]++;
            Losses[lobbyInfo[_gameId].player2]++;
        }

        else {
            lobbyInfo[_gameId].winner=lobbyInfo[_gameId].player2;
            Wins[lobbyInfo[_gameId].player2]++;
            Losses[lobbyInfo[_gameId].player1]++;
        }

        lobbyInfo[_gameId].completed=true;
    }

    /// @notice Random number generator. Generates number from 1 to 99 (not a true 50/50, but does the job). 
    /// @notice Second player pays a little more in gas fees, so he gets 0.5% bonus.
    /// @dev Using keccak256 is not a very secure way. If launched to public, should be changed to oracle.
    function randMod() internal returns(uint) {
        Randnonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, Randnonce))) % 100;
    }

    /// @notice Looks into game chosen struct price and duplicates it for cashout.
    function CashoutWinnings(uint _gameId) public {
        require(lobbyInfo[_gameId].completed, "Game not completed");
        require(msg.sender==lobbyInfo[_gameId].winner, "You are not winner in this game, check game ID");
        uint Winnings=lobbyInfo[_gameId].gamePrice * 2;
        payable(msg.sender).transfer(Winnings);
    }
}