// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MOONToken is ERC20 {
    mapping(address => uint256) private _times; // record the address withdraw last time and times
    //_times value: times * 1000000000000 + timestamp 
    //get the times: value / 1000000000000 (the decimal will be delete)
    //get the last withdraw timestamp: value - (1000000000000 * times)
    address public _token;
    uint256 public _max; // (how many times can withdraw all token)
    uint256 public _time; // (wait seconds)
    constructor(uint256 max,uint256 time,address token) ERC20("moon", "moon") {
        _max = max;
        _time = time;
        _token = token;
    }
    
    
    
    //swap moon to sun limited by the times 
    function status() public view returns (uint256,uint256) {
        if (_times[msg.sender] != 0) {
            uint256 times = _times[msg.sender] / 1000000000000;
            return (times,_times[msg.sender] - times * 1000000000000);
        }else {
            return (0,0);
        }
    
    }
    
    //now can withdraw number
    function discount(address addr) public view returns (uint256,uint256) {
        uint256 times;
        uint256 time;
        (times,time) = status(); //had withdraw times
        uint256 nums = (block.timestamp - time) / _time;
  
        if (balanceOf(addr) == 0 || nums == 0){
            return (0,0);
        }
        //this block can be withdraw times
        if (nums + times >= _max) {
            return (balanceOf(addr),_max);
        }else{
            uint256 max = _max - times - 1;
            uint256 value = 2 ** max - 2 ** (max - nums);
            uint256 amount = balanceOf(addr) * value / (2 ** max);
            return (amount,times+nums);
        }
    }
    
    function withdraw() public {
        //default withdraw all of the address can withdrawd now
        uint256 amount;
        uint256 times;
        (amount,times) = discount(msg.sender);
        require(amount!=0,"balance is zero");
        require(transfer(address(0xdead),amount));
        require(IERC20(_token).transfer(msg.sender,amount));
        if (times == _max) {
            _times[msg.sender] = 0;
        }else {
            _times[msg.sender] = times * 1000000000000 + block.timestamp;
        }
    }

    //swap sun to moon
    function swap(uint256 amount) public {
        require(IERC20(_token).transferFrom(msg.sender,address(this),amount),"transferFrom failed");
        _mint(msg.sender,amount);
        _times[msg.sender] = block.timestamp;
    }
}
