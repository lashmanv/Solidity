// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
//import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Estate is ERC1155,Ownable,AccessControl{
    using SafeMath for uint256;

    address _admin;
    uint256 tokenIdCount = 1;

    struct Token{
        string name;
        string symbol;
        uint256 amount;
    }

    mapping (uint256 => Token) internal tokenDatabase;

    mapping (uint256 => address[]) internal tokenHolders;

    mapping (uint256 => string) internal tokenUri;

    constructor() ERC1155("") {
        _admin = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ADMIN_ROLE, _admin);
    }


    function mint(string memory _tokenname,string memory _symbol, uint256 _amount,string memory _tokenUri) public onlyOwner {
        address admin = _msgSender();
        uint256 count = tokenIdCount;

        require(
            bytes(_tokenname).length != 0,
            "Estate protocol: Token name can't be blank."
        );
        require(
            bytes(_symbol).length != 0,
            "Estate protocol: Token symbol can't be blank."
        );
        require(
            bytes(_tokenUri).length != 0,
            "Estate protocol: Token URI can't be blank."
        );
        require(
            _amount > 0,
            "Estate protocol: Token amount can't be zero."
        );

        tokenDatabase[tokenIdCount] = Token(_tokenname,_symbol,_amount);
        _mint(admin, tokenIdCount, _amount, bytes(_tokenUri));
        tokenUri[tokenIdCount] = _tokenUri;
        tokenHolders[tokenIdCount].push(admin);
        tokenIdCount = tokenIdCount.add(1);

        emit Mint(count,_tokenname,_symbol,_amount,_tokenUri);
    }

    function burn(address from,uint256 _tokenId,uint256 _amount) public onlyOwner {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(
           (_tokenId > 0) && _tokenId <= tokenIdCount,"Estate protocol: invalid Token Id."
        );

        _burn(from,_tokenId,_amount);

        uint256 updatedBalance = balanceOf(from,_tokenId);
        address[] storage memberArry = tokenHolders[_tokenId];

        if(updatedBalance == 0) {
            for(uint256 i = 0; i <= memberArry.length-1; i++) {
                if(memberArry[i] == from ) {
                    if(memberArry[i++] == from && (i+1) < memberArry.length) {
                        memberArry[i] = memberArry[i.add(1)];
                    }
                    else if(memberArry[i++] == from && (i+1) == memberArry.length) {
                        memberArry[i] = memberArry[i.sub(1)]; 
                    }               
                    if(memberArry[i++] != from && (i+1) < memberArry.length) {
                        memberArry[i] = memberArry[i.add(1)];
                    }
                }
                memberArry.pop();
            }
        }

        tokenHolders[_tokenId] = memberArry;
        
        emit Burn(_tokenId);
    }

    function safeTransferFrom(address from,address to,uint256 _tokenId,uint256 _amount, bytes memory data) public virtual override {
        require(from != address(0), "Estate protocol: invalid address");
        require(to != address(0), "Estate protocol: invalid address");
        require(
            _tokenId <= tokenIdCount,"Estate protocol: invalid Token Id."
        );
        uint256 tempBalance = balanceOf(to,_tokenId);
        
        super._safeTransferFrom(from,to,_tokenId,_amount,"");

        uint256 updatedBalance = balanceOf(from,_tokenId);
        address[] storage memberArry = tokenHolders[_tokenId];

        if( tempBalance == 0) {
            tokenHolders[_tokenId].push(to);
        }        

        if(updatedBalance == 0) {
            for(uint256 i = 0; i <= memberArry.length-1; i++) {
                if(memberArry[i] == from ) {
                    memberArry[i] = memberArry[i.add(1)];                
                
                    if(memberArry[i++] != from && (i+1) < memberArry.length) {
                        memberArry[i] = memberArry[i.add(1)];
                    }
                }
                memberArry.pop();
            }
        }

        tokenHolders[_tokenId] = memberArry;

        emit Transfer(from,to,_amount);
    }


    function safeBatchTransferFrom(address from,address to,uint256[] memory _tokenIds,uint256[] memory _amount,bytes memory data) public virtual override{
        require(from != address(0), "Estate protocol: invalid address");
        require(to != address(0), "Estate protocol: invalid address");
        
        super._safeBatchTransferFrom(from,to,_tokenIds,_amount,"");

        uint256[] memory updatedBalance;
        bool alreadyMembr = false;

        for(uint256 i = 0; i <= _tokenIds.length; i++) {
            updatedBalance[i] = balanceOf(from,_tokenIds[i]);
            if(tokenHolders[_tokenIds[i]][i] == to){
                alreadyMembr = true;
            }
            if(alreadyMembr == false){
                tokenHolders[_tokenIds[i]].push(to);
            }
        }
        
        for(uint256 i = 0; i <= updatedBalance.length-1; i++) {
            if(updatedBalance[i] == 0) {
                address[] storage memberArry = tokenHolders[_tokenIds[i]];
                for(uint256 j = 0; j <= memberArry.length-1; j++) {
                    if(memberArry[i] == from && (i+1) < memberArry.length) {
                        memberArry[i] = memberArry[i.add(1)];                
                
                        if(memberArry[i++] != from && (i+1) < memberArry.length) {
                            memberArry[i] = memberArry[i.add(1)];
                            memberArry.pop();
                        }
                    }
                    else if(memberArry[i] == from && (i+1) == memberArry.length){
                        memberArry.pop();
                    }
                }
                tokenHolders[_tokenIds[i]] = memberArry;
            }
        }
    }


    function changeTokenUri(uint256 _tokenId,string memory _tokenUri) public onlyOwner {
        require(
            _tokenId <= tokenIdCount,
            "Estate protocol: invalid token Id."
        );
        require(
            bytes(_tokenUri).length != 0,
            "Estate protocol: invalid tokenuri."
        );

        tokenUri[_tokenId] = _tokenUri;

        emit NewTokenUri(_tokenUri);
    }
    
    function _getTokenHolders(uint256 _tokenId) public view returns(address[] memory) {
        return tokenHolders[_tokenId];
    }

    function TokenDatabase(uint256 _tokenId) public view returns (string memory,string memory,uint256) {
        require(
            bytes(tokenUri[_tokenId]).length != 0,
            "Estate protocol: invalid token Id."
        );

       return (tokenDatabase[_tokenId].name,tokenDatabase[_tokenId].symbol,tokenDatabase[_tokenId].amount);
    }

    function TokenUri (uint256 _tokenId) public view returns (string memory) {
        require(
            bytes(tokenUri[_tokenId]).length != 0,
            "Estate protocol: invalid token Id."
        );

        return tokenUri[_tokenId];
    }

    
    ERC20 USDTToken = ERC20(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8);

    uint256 _houseIdCount = 1;

    struct Home {
        //map Home ID
        uint256 houseId;
        address houseOwner;
        uint256 housePrice;
        uint256 minSharePercent;
        uint256 maxSharePercent;
        uint256 remainingShare;
        uint256 usdtPercent;
        bool rentActivity;
    }

    mapping(uint256 => Home) public houseContract;
    mapping(uint256 => mapping(address => uint256)) internal holderSharePercent;
    mapping(address => uint256) internal usdtBalance;

    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function _setUpNewHouse(address _houseOwner,uint256 _housePrice,uint256 _minSharePercent,uint256 _maxSharePercent,uint256 _usdtPercent) internal {
        address user = _msgSender();
        require(user != address(0), "invalid address");
        
        require(_houseOwner != address(0), "Chainestate Protocol: Invalid address.");
        require(_housePrice > 0, "Chainestate Protocol: House Price can't be zero.");
        require(_minSharePercent > 0 && _minSharePercent < 100, "Chainestate Protocol: Share percent can't be zero.");
        require(_maxSharePercent > _minSharePercent && _maxSharePercent <= 100, "Chainestate Protocol: Share percent can't be zero.");

        houseContract[_houseIdCount].houseId = _houseIdCount;
        houseContract[_houseIdCount].houseOwner = _houseOwner;
        houseContract[_houseIdCount].housePrice = _housePrice;
        houseContract[_houseIdCount].minSharePercent = _minSharePercent;
        houseContract[_houseIdCount].maxSharePercent = _maxSharePercent;
        houseContract[_houseIdCount].remainingShare = _housePrice;
        houseContract[_houseIdCount].usdtPercent = _usdtPercent;
        houseContract[_houseIdCount].rentActivity = false;

        _houseIdCount = _houseIdCount.add(1);
    }

    function createNewHouse(address _houseOwner, uint256 _housePrice, uint256 _minSharePercent, uint256 _maxSharePercent, uint256 _usdtPercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setUpNewHouse(_houseOwner,_housePrice,_minSharePercent,_maxSharePercent,_usdtPercent);

        emit HouseCreated(_houseIdCount,_houseOwner,_housePrice,_minSharePercent,_maxSharePercent);
    }

    function _buyAShare(uint256 _houseId,uint256 _amount) internal {
        address user = _msgSender();
        require(user != address(0), "invalid address");

        require(_houseId != 0 && _houseId <= _houseIdCount, "Chainestate Protocol: Invalid HouseId.");
        require(_amount > 0, "Chainestate Protocol: Amount can't be zero.");

        uint256  propertyPrice = houseContract[_houseId].housePrice;
        uint256  remainingShare = houseContract[_houseId].remainingShare;
        uint256 maxSharePercent = houseContract[_houseId].maxSharePercent;

        uint8 usdtDecimals = USDTToken.decimals();

        uint256 amount = _amount.mul(10**usdtDecimals);

        uint256 propertyShare = balanceOf(user, _houseId);
        uint256 finalAmount = amount.add(propertyShare);

        uint256 sharePercent = finalAmount.div(propertyPrice).mul(100);

        require(sharePercent <= maxSharePercent, "Chainestate Protocol: Amount should be less than maxShare Percent.");
        require(amount <= remainingShare, "Chainestate Protocol: Amount should be less than remaining share.");

        USDTToken.transferFrom(user, address(this), amount);

        safeTransferFrom(_admin,user,_houseId,amount,"");

        houseContract[_houseId].remainingShare = remainingShare.sub(amount);

        holderSharePercent[_houseId][user] = sharePercent;

        usdtBalance[user] = usdtBalance[user].add(amount);
    }

    function buyAShareofProperty(uint256 _houseId, uint256 _amount) public {
        _buyAShare(_houseId,_amount);

        emit ShareBought(_houseId,_amount);
    }

    function _sellAShare(address _to,uint256 _houseId,uint256 _amount) internal {
        address user = _msgSender();
        require(user != address(0), "invalid address");

        require(_houseId != 0 && _houseId <= _houseIdCount, "Chainestate Protocol: Invalid HouseId.");
        require(_amount > 0, "Chainestate Protocol: Amount can't be zero.");

        uint256  propertyShare = balanceOf(user, _houseId);

        require(_amount <= propertyShare, "Chainestate Protocol: Insufficient property share.");

        safeTransferFrom(user,_to,_houseId,_amount,"");

        USDTToken.transferFrom(_to,user, _amount);

        usdtBalance[user] = usdtBalance[user].sub(_amount);

        uint256  propertyPrice = houseContract[_houseId].housePrice;
        
        uint256 finalAmount = _amount.sub(propertyShare);

        uint256 sharePercent = finalAmount.div(propertyPrice).mul(100);

        holderSharePercent[_houseId][user] = sharePercent;
    }

    function sellAShareofProperty(address _to,uint256 _houseId, uint256 _amount) public {
        _sellAShare(_to,_houseId,_amount);

        emit ShareSold(_houseId,_amount);
    }

    function changeRentActivity(uint256 _houseId) external onlyRole(DEFAULT_ADMIN_ROLE){
        addressRequireChecks();

        bool rentActivity = houseContract[_houseId].rentActivity;

        if (rentActivity == false) {
            rentActivity = true;
        } 
        else {
            rentActivity = false;
        }
        
        houseContract[_houseId].rentActivity = rentActivity;

        emit RentActivity(_houseId,rentActivity);
    }

    function updateHouseMinSharePercent(uint256 _houseId, uint256 _newMinSharePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addressRequireChecks();
        require(_houseId != 0 && _houseId <= _houseIdCount, "Chainestate Protocol: Invalid HouseId.");

        houseContract[_houseIdCount].minSharePercent = _newMinSharePercent;

        emit  SharePercent(_houseId,_newMinSharePercent);
    }

    function updateHouseMaxSharePercent(uint256 _houseId, uint256 _newMaxSharePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addressRequireChecks();
        require(_houseId != 0 && _houseId <= _houseIdCount, "Chainestate Protocol: Invalid HouseId.");

        houseContract[_houseIdCount].maxSharePercent = _newMaxSharePercent;

        emit  SharePercent(_houseId,_newMaxSharePercent);
    }
    


    // Query functions
    function getHouseMaxSharePercent(uint256 _houseId) public view returns (uint256) {
        addressRequireChecks();

        require(_houseId != 0 && _houseId <= _houseIdCount, "Chainestate Protocol: Invalid HouseId.");

        uint256 propertyMaxSharePercent = houseContract[_houseIdCount].maxSharePercent;

        return (propertyMaxSharePercent);
    }

    function getHouseMinSharePercent(uint256 _houseId) public view returns (uint256) {
        addressRequireChecks();

        require(_houseId != 0 && _houseId <= _houseIdCount, "Chainestate Protocol: Invalid HouseId.");

        uint256 propertyMinSharePercent = houseContract[_houseIdCount].minSharePercent;

        return (propertyMinSharePercent);
    }

    
    function getLatestHouseCounter() public view returns (uint256) {
        addressRequireChecks();

        uint256 fetchedId;

        if (_houseIdCount == 1) {
        fetchedId = 1;
        } else {
        fetchedId = _houseIdCount - 1;
        }

        return (fetchedId);
    }

    function amountToPercent(uint256 _houseId, uint256 _amount) public view returns(uint256) {
        address user = _msgSender();
        require(user != address(0), "invalid address");

        require(_houseId != 0 && _houseId <= _houseIdCount, "Chainestate Protocol: Invalid HouseId.");
        require(_amount > 0, "Chainestate Protocol: Amount can't be zero.");

        uint256  propertyPrice = houseContract[_houseId].housePrice;

        uint8 usdtDecimals = USDTToken.decimals();

        uint256  percent = _amount.mul(10**usdtDecimals).div(propertyPrice).mul(100);

        return percent;
    }

    function getHouseShare(uint256 _houseId) public view returns(uint256) {
        address user = _msgSender();
        require(user != address(0), "invalid address");

        require(_houseId != 0 && _houseId <= _houseIdCount, "Chainestate Protocol: Invalid HouseId.");

        uint256  propertyShare = balanceOf(user, _houseId);

        return propertyShare;
    }

    function getHolderSharePercent(uint256 _houseId) public view returns(uint256) {
        address user = _msgSender();
        require(user != address(0), "invalid address");

        require(_houseId != 0 && _houseId <= _houseIdCount, "Chainestate Protocol: Invalid HouseId.");

        uint256  sharePercent = holderSharePercent[_houseId][user];

        return sharePercent;
    }

    function getHouseShareHolders(uint256 _houseId) public view {
        _getTokenHolders(_houseId);
    }   

    // this function might be usefull to query for the user usdt tokens to display in frontend when the user connects his wallet
    function USDTBalance(address _user) public view returns (uint256) {
        address user = _msgSender();
        require(user != address(0), "invalid address");

        uint256 QueryBalance = USDTToken.balanceOf(_user);
        return QueryBalance;
    }

    // view user address
    function getuserAddress() public view returns (address) {
        address userAddress = _msgSender();
        return userAddress;
    }

    // this function is to add a new admin
    // admins are allowed to create, end and distribute rewards of smart contract proposals
    function addAdmin(address approvedAdmin) public {
        require(
        hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
        "Chainestate Protocol: Caller is not a main admin."
        );
        require(approvedAdmin != address(0), "Chainestate Protocol: invalied address.");

        grantRole(ADMIN_ROLE, approvedAdmin);
    }

    // this function is to remove a current admin
    // admins removed can't create,end and distribute rewards of smart contracts proposals
    function removeAdmin(address removedAdmin) public {
        require(
        hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
        "Chainestate Protocol: Caller is not a main admin."
        );
        require(removedAdmin != address(0), "Chainestate Protocol: invalied address.");

        require(
        removedAdmin != _admin,
        "Chainestate Protocol: Defult admin cannot remove himself from being admin."
        );

        // remove the admin role from an address
        revokeRole(ADMIN_ROLE, removedAdmin);
    }

    // this function is a check function just to make sure that the user (addrtess) that implement the function is an admin
    function isAdminCheck(address user) public view {
        require(
        hasRole(ADMIN_ROLE, user),
        "Chainestate Protocol: this address is not an admin."
        );
    }

    function addressRequireChecks() internal view {
        address user = _msgSender();
        require(user != address(0), "invalid address");
    }

   
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    event HouseCreated(
        uint256 houseId,
        address houseOwner,
        uint256 maxPrice,
        uint256 minSharePercent,
        uint256 maxShareAmount
    );

    event ShareBought(uint256 houseId,uint256 amount);
    event ShareSold(uint256 houseId,uint256 amount);
    event SharePercent(uint256 houseId,uint256 sharePercent);
    event RentActivity(uint256 houseId,bool activity);

    event Mint(uint256 _tokenId, string _tokenname, string _tokensymbol, uint256 _tokenamount, string _tokenuri);

    event Burn(uint256 _tokenId);

    event NewTokenUri(string _tokenUri);

    event Transfer(address from,address to,uint256 _amount);

}
