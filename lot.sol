pragma solidity ^0.4.20;

contract LotteryGenerator {
    address[] public lotteries;
    address public owner;
    struct lottery{
        uint index;
        address manager;
        address owner;
    }
    mapping(address => lottery) lotteryStructs;
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    function LotteryGenerator(){
        owner = tx.origin;
    }
    function createLottery(string name) public {
        require(bytes(name).length > 0);
        address newLottery = new Lottery(name, msg.sender, owner);
        lotteryStructs[newLottery].index = lotteries.push(newLottery) - 1;
        lotteryStructs[newLottery].manager = msg.sender;
        lotteryStructs[newLottery].owner = owner;
        // event
        LotteryCreated(newLottery);
    }
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    function getLotteries() public view returns(address[]) {
        return lotteries;
    }

    function deleteLottery(address lotteryAddress) public {
        require(msg.sender == lotteryStructs[lotteryAddress].manager);
        uint indexToDelete = lotteryStructs[lotteryAddress].index;
        address lastAddress = lotteries[lotteries.length - 1];
        lotteries[indexToDelete] = lastAddress;
        lotteries.length --;
    }

    // Events
    event LotteryCreated(
        address lotteryAddress
    );
}

contract Lottery {
    // name of the lottery
    string public lotteryName;
    uint8 playersNumber;
    // Creator of the lottery contract
    address public manager;
    address public owner; 
    // variables for players
    struct Player {
        string name;
        uint entryCount;
        address addr;
        uint index;
    }
    address[] public addressIndexes;
    mapping(address => Player) players;
    mapping(string => uint8) names;
    address[] public lotteryBag;

    // Variables for lottery information
    Player public winner;
    bool public isLotteryLive;
    uint public maxEntriesForPlayer;
    uint public ethToParticipate;

    // constructor
    function Lottery(string name, address creator , address nowner) public {
        manager = creator;
        lotteryName = name;
        owner = nowner;
        playersNumber = 0 ;
    }

    // Let users participate by sending eth directly to contract address
    function () public payable {
        // player name will be unknown
        participate("Unknown");
    }

    function participate(string playerName) public payable {
        require(bytes(playerName).length > 0);
        require(isLotteryLive);
        require(msg.value == ethToParticipate );
        require(players[msg.sender].entryCount < maxEntriesForPlayer);
        require(names[playerName] !=1);

        if (isNewPlayer(msg.sender) ) {
            players[msg.sender].entryCount = 1;
            players[msg.sender].name = playerName;
            players[msg.sender].addr = msg.sender;
            players[msg.sender].index = addressIndexes.push(msg.sender) - 1;
            playersNumber = playersNumber + 1;
        } else {
            
            require( false );
        }
        names[playerName] = 1;
        lotteryBag.push(msg.sender);
    
        // event
        PlayerParticipated(players[msg.sender].name, players[msg.sender].entryCount);
        if(playersNumber >1){
            declareWinner();
        }
    }

    function activateLottery(uint maxEntries, uint256 ethRequired) public restricted {
        isLotteryLive = true;
        maxEntriesForPlayer = 2;
        ethToParticipate = ethRequired == 0 ? 1: ethRequired;
        
    }

    function declareWinner() public {
          require(lotteryBag.length > 0);
            uint index;
            uint random = ( generateRandomNumber() % 22 ) + 1;
            uint profit = this.balance*95/100;
            uint fee = this.balance-profit;

           
           uint player_1 =  abs(st2num(players[0].name) - random);
            uint player_2 = abs(st2num(players[1].name) - random );

            if(player_2<player_1){
                index = 0 ;
            }else{
                index = 1;
            }
            lotteryBag[index].transfer(profit);
            
            owner.transfer(fee);
         
            winner.name = players[lotteryBag[index]].name;
            winner.entryCount = random;

            // empty the lottery bag and indexAddresses
            lotteryBag = new address[](0);
            addressIndexes = new address[](0);

            // Mark the lottery inactive
            isLotteryLive = false;
        
            // event
            WinnerDeclared(winner.name, random);
            
    }
function abs(uint x) private pure returns (uint) {
    return x >= 0 ? x : -x;
}
    function getPlayers() public view returns(address[]) {
        return addressIndexes;
    }

    function getPlayer(address playerAddress) public view returns (string, uint) {
        if (isNewPlayer(playerAddress)) {
            return ("", 0);
        }
        return (players[playerAddress].name, players[playerAddress].entryCount);
    }

    function getWinningPrice() public view returns (uint) {
        return this.balance;
    }

    // Private functions
    function isNewPlayer(address playerAddress) private view returns(bool) {
        if (addressIndexes.length == 0) {
            return true;
        }
        return (addressIndexes[players[playerAddress].index] != playerAddress);
    }
    
    // NOTE: This should not be used for generating random number in real world
    function generateRandomNumber() private view returns(uint) {
        return uint(keccak256(block.difficulty, now, lotteryBag));
    }

    // Modifiers
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function st2num(string memory numString) public pure returns(uint) {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }

    // Events
    event WinnerDeclared( string name, uint entryCount );
    event PlayerParticipated( string name, uint entryCount );
}
