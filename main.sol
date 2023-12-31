/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

// ██████  ███████ ██    ██  ██████  ██      ██    ██ ███████ ██  ██████  ███    ██                   
// ██   ██ ██      ██    ██ ██    ██ ██      ██    ██     ██  ██ ██    ██ ████   ██                  
// ██████  █████   ██    ██ ██    ██ ██      ██    ██   ██    ██ ██    ██ ██ ██  ██                   
// ██   ██ ██       ██  ██  ██    ██ ██      ██    ██  ██     ██ ██    ██ ██  ██ ██                   
// ██   ██ ███████   ████    ██████  ███████  ██████  ███████ ██  ██████  ██   ████    

// SAFU CONTRACT BY REVOLUZION

//Revoluzion Ecosystem
//WEB: https://revoluzion.io
//DAPP: https://revoluzion.app

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// Library

abstract contract Ownable {
    
    // DATA

    address private _owner;

    // MODIFIER

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    // CONSTRUCTOR

    constructor() {
        _transferOwnership(msg.sender);
    }

    // EVENT

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // FUNCTION

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Interface

interface IERC20 {
    
    //EVENT 

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // FUNCTION

    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address to, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IFactory {

    // FUNCTION

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {

    // FUNCTION

    function WETH() external pure returns (address);
        
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
}

// Token

contract CrashBandicoin is Ownable, IERC20 {

    // DATA

    string private constant NAME = "Crash Bandicoin";
    string private constant SYMBOL = "CBC";

    uint8 private constant DECIMALS = 9;

    uint256 private _totalSupply;
    
    uint256 public constant FEEDENOMINATOR = 10_000;

    uint256 public buyMarketingFee = 200;
    uint256 public buyNitroFee = 100;
    uint256 public sellMarketingFee = 200;
    uint256 public sellNitroFee = 100;
    uint256 public transferMarketingFee = 0;
    uint256 public transferNitroFee = 0;
    uint256 public marketingFeeCollected = 0;
    uint256 public nitroFeeCollected = 0;
    uint256 public totalFeeCollected = 0;
    uint256 public marketingFeeRedeemed = 0;
    uint256 public nitroFeeRedeemed = 0;
    uint256 public totalFeeRedeemed = 0;
    uint256 public minSwap = 100_000 gwei;

    bool private constant ISCBC = true;

    bool public tradeEnabled = false;
    bool public isFeeActive = false;
    bool public isFeeLocked = false;
    bool public isSwapEnabled = false;
    bool public inSwap = false;

    address public immutable projectOwner;

    address public constant ZERO = address(0);
    address public constant DEAD = address(0xdead);

    address public nitroReceiver = 0x1c1851ff52E3AEcC7bEc524a0fB2F3F8F1616946;
    address public marketingReceiver = 0xE9aDAA0C22979d3DA28d77EE255756a522641796;

    address public pair;
    address public presaleAddress;
    address public presaleFactory;
    
    IRouter public router;

    // MAPPING

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludeFromFees;

    // MODIFIER

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // CONSTRUCTOR

    constructor(
        address routerAddress,
        address projectOwnerAddress
    ) Ownable () {
        require(projectOwnerAddress != ZERO, "Cannot set project owner address as zero address.");
        _mint(msg.sender, 1_000_000_000 gwei);
        projectOwner = projectOwnerAddress;

        isExcludeFromFees[routerAddress] = true;
        router = IRouter(routerAddress);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
    }

    // EVENT

    event UpdateRouter(address oldRouter, address newRouter, uint256 timestamp);

    event UpdateMinSwap(uint256 oldMinSwap, uint256 newMinSwap, uint256 timestamp);

    event UpdateFeeActive(bool oldStatus, bool newStatus, uint256 timestamp);

    event UpdateSwapEnabled(bool oldStatus, bool newStatus, uint256 timestamp);

    event UpdateMarketingReceiver(address oldMarketingReceiver, address newMarketingReceiver, uint256 timestamp);
    
    event UpdateNitroReceiver(address oldNitroReceiver, address newNitroReceiver, uint256 timestamp);

    event UpdateBuyFee(uint256 oldMarketingFee, uint256 oldNitroFee, uint256 newMarketingFee, uint256 newNitroFee, uint256 timestamp);

    event UpdateSellFee(uint256 oldMarketingFee, uint256 oldNitroFee, uint256 newMarketingFee, uint256 newNitroFee, uint256 timestamp);

    event UpdateTransferFee(uint256 oldMarketingFee, uint256 oldNitroFee, uint256 newMarketingFee, uint256 newNitroFee, uint256 timestamp);

    event AutoRedeem(uint256 marketingFeeDistribution, uint256 nitroFeeDistribution, uint256 amountToRedeem, uint256 timestamp);

    event SetPresaleAddress(address adr, uint256 timestamp);

    event SetPresaleFactory(address adr, uint256 timestamp);

    event NativeTransfer(address beneficiary, uint256 amount);

    // FUNCTION

    /* General */

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradeEnabled, "Enable Trading: Trading already enabled.");
        require(!isFeeActive, "Finalize Presale: Fee already active.");
        require(!isSwapEnabled, "Finalize Presale: Swap already enabled.");
        tradeEnabled = true;
        isFeeActive = true;
        isSwapEnabled = true;
    }

    function finalizePresale() external onlyOwner {
        require(!isFeeActive, "Finalize Presale: Fee already active.");
        require(!isSwapEnabled, "Finalize Presale: Swap already enabled.");
        isFeeActive = true;
        isSwapEnabled = true;
    }

    function lockFees() external onlyOwner {
        require(!isFeeLocked, "Lock Fees: All fees were already locked.");
        isFeeLocked = true;
    }
    
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function redeemAllMarketingFee() external {
        uint256 amountToRedeem = marketingFeeCollected - marketingFeeRedeemed;
        
        _redeemMarketingFee(amountToRedeem);
    }

    function redeemPartialMarketingFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= marketingFeeCollected - marketingFeeRedeemed, "Redeem Partial Marketing Fee: Insufficient marketing fee collected.");
        
        _redeemMarketingFee(amountToRedeem);
    }

    function _redeemMarketingFee(uint256 amountToRedeem) internal swapping { 
        marketingFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToRedeem);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToRedeem,
            0,
            path,
            marketingReceiver,
            block.timestamp
        );
    }

    function redeemAllNitroFee() external {
        uint256 amountToRedeem = nitroFeeCollected - nitroFeeRedeemed;
        
        _redeemNitroFee(amountToRedeem);
    }

    function redeemPartialNitroFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= nitroFeeCollected - nitroFeeRedeemed, "Redeem Partial Nitro Fee: Insufficient nitro fee collected.");
        
        _redeemNitroFee(amountToRedeem);
    }

    function _redeemNitroFee(uint256 amountToRedeem) internal swapping { 
        nitroFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToRedeem);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToRedeem,
            0,
            path,
            nitroReceiver,
            block.timestamp
        );
    }

    /* Check */

    function isCBC() external pure returns (bool) {
        return ISCBC;
    }

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(ZERO);
    }

    /* Update */

    function updateRouter(address newRouter) external onlyOwner {
        require(address(router) != newRouter, "Update Router: This is the current router address.");
        address oldRouter = address(router);
        router = IRouter(newRouter);
        emit UpdateRouter(oldRouter, newRouter, block.timestamp);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
    }

    function updateMinSwap(uint256 newMinSwap) external onlyOwner {
        require(minSwap != newMinSwap, "Update Min Swap: This is the current value of min swap.");
        uint256 oldMinSwap = minSwap;
        minSwap = newMinSwap;
        emit UpdateMinSwap(oldMinSwap, newMinSwap, block.timestamp);
    }

    function updateBuyFee(uint256 newMarketingFee, uint256 newNitroFee) external onlyOwner {
        require(!isFeeLocked, "Update Buy Fee: All buy fees were locked and cannot be updated.");
        require(newMarketingFee + newNitroFee <= 1000, "Update Buy Fee: Total fees cannot exceed 10%.");
        uint256 oldMarketingFee = buyMarketingFee;
        uint256 oldNitroFee = buyNitroFee;
        buyMarketingFee = newMarketingFee;
        buyNitroFee = newNitroFee;
        emit UpdateBuyFee(oldMarketingFee, oldNitroFee, newMarketingFee, newNitroFee, block.timestamp);
    }

    function updateSellFee(uint256 newMarketingFee, uint256 newNitroFee) external onlyOwner {
        require(!isFeeLocked, "Update Sell Fee: All sell fees were locked and cannot be updated.");
        require(newMarketingFee + newNitroFee <= 1000, "Update Sell Fee: Total fees cannot exceed 10%.");
        uint256 oldMarketingFee = sellMarketingFee;
        uint256 oldNitroFee = sellNitroFee;
        sellMarketingFee = newMarketingFee;
        sellNitroFee = newNitroFee;
        emit UpdateSellFee(oldMarketingFee, oldNitroFee, newMarketingFee, newNitroFee, block.timestamp);
    }

    function updateTransferFee(uint256 newMarketingFee, uint256 newNitroFee) external onlyOwner {
        require(!isFeeLocked, "Update Transfer Fee: All transfer fees were locked and cannot be updated.");
        require(newMarketingFee + newNitroFee <= 1000, "Update Transfer Fee: Total fees cannot exceed 10%.");
        uint256 oldMarketingFee = transferMarketingFee;
        uint256 oldNitroFee = transferNitroFee;
        transferMarketingFee = newMarketingFee;
        transferNitroFee = newNitroFee;
        emit UpdateTransferFee(oldMarketingFee, oldNitroFee, newMarketingFee, newNitroFee, block.timestamp);
    }

    function updateFeeActive(bool newStatus) external onlyOwner {
        require(isFeeActive != newStatus, "Update Fee Active: This is the current state for the fee.");
        bool oldStatus = isFeeActive;
        isFeeActive = newStatus;
        emit UpdateFeeActive(oldStatus, newStatus, block.timestamp);
    }

    function updateSwapEnabled(bool newStatus) external onlyOwner {
        require(isSwapEnabled != newStatus, "Update Swap Enabled: This is the current state for the swap.");
        bool oldStatus = isSwapEnabled;
        isSwapEnabled = newStatus;
        emit UpdateSwapEnabled(oldStatus, newStatus, block.timestamp);
    }

    function updateMarketingReceiver(address newMarketingReceiver) external onlyOwner {
        require(marketingReceiver != newMarketingReceiver, "Update Marketing Receiver: This is the current marketing receiver address.");
        require(!isContract(newMarketingReceiver), "Update Marketing Receiver: Cannot set contract or EOA as marketing receiver address.");
        address oldMarketingReceiver = marketingReceiver;
        marketingReceiver = newMarketingReceiver;
        emit UpdateMarketingReceiver(oldMarketingReceiver, newMarketingReceiver, block.timestamp);
    }

    function updateNitroReceiver(address newNitroReceiver) external onlyOwner {
        require(nitroReceiver != newNitroReceiver, "Update Nitro Receiver: This is the current nitro receiver address.");
        require(!isContract(newNitroReceiver), "Update Nitro Receiver: Cannot set contract or EOA as nitro receiver address.");
        address oldNitroReceiver = nitroReceiver;
        nitroReceiver = newNitroReceiver;
        emit UpdateNitroReceiver(oldNitroReceiver, newNitroReceiver, block.timestamp);
    }

    function setPresaleFactory(address adr) external onlyOwner {
        require(adr != address(0), "Set Presale Factory: Cannot set zero address as presale factory address.");
        require(adr != presaleFactory, "Set Presale Factory: Cannot set the same address.");
        presaleFactory = adr;
        isExcludeFromFees[adr] = true;
        emit SetPresaleFactory(adr, block.timestamp);
    }

    function setPresaleAddress(address adr) external onlyOwner {
        require(adr != address(0), "Set Presale Address: Cannot set zero address as presale address.");
        require(adr != presaleAddress, "Set Presale Address: Cannot set the same address.");
        presaleAddress = adr;
        isExcludeFromFees[adr] = true;
        emit SetPresaleAddress(adr, block.timestamp);
    }

    function setExcludeFromFees(address user, bool status) external onlyOwner {
        require(isExcludeFromFees[user] != status, "Set Exclude From Fees: This is the current state for this address.");
        isExcludeFromFees[user] = status;
    }

    /* Fee */

    function takeBuyFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeTotal = buyMarketingFee + buyNitroFee;
        uint256 feeAmount = amount * feeTotal / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallyBuyFee(from, feeAmount, feeTotal);
        return newAmount;
    }

    function takeSellFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeTotal = sellMarketingFee + sellNitroFee;
        uint256 feeAmount = amount * feeTotal / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallySellFee(from, feeAmount, feeTotal);
        return newAmount;
    }

    function takeTransferFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeTotal = transferMarketingFee + transferNitroFee;
        uint256 feeAmount = amount * feeTotal / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallyTransferFee(from, feeAmount, feeTotal);
        return newAmount;
    }

    function tallyBuyFee(address from, uint256 amount, uint256 fee) internal swapping {
        uint256 collectMarketing = amount * buyMarketingFee / fee;
        uint256 collectNitro = amount - collectMarketing;
        tallyCollection(collectMarketing, collectNitro, amount);
        
        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function tallySellFee(address from, uint256 amount, uint256 fee) internal swapping {
        uint256 collectMarketing = amount * sellMarketingFee / fee;
        uint256 collectNitro = amount - collectMarketing;
        tallyCollection(collectMarketing, collectNitro, amount);
        
        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function tallyTransferFee(address from, uint256 amount, uint256 fee) internal swapping {
        uint256 collectMarketing = amount * transferMarketingFee / fee;
        uint256 collectNitro = amount - collectMarketing;
        tallyCollection(collectMarketing, collectNitro, amount);

        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function tallyCollection(uint256 collectMarketing, uint256 collectNitro, uint256 amount) internal swapping {
        marketingFeeCollected += collectMarketing;
        nitroFeeCollected += collectNitro;
        totalFeeCollected += amount;

    }

    function autoRedeem(uint256 amountToRedeem) public swapping {  
        uint256 marketingToRedeem = marketingFeeCollected - marketingFeeRedeemed;
        uint256 totalToRedeem = totalFeeCollected - totalFeeRedeemed;

        uint256 marketingFeeDistribution = amountToRedeem * marketingToRedeem / totalToRedeem;
        uint256 nitroFeeDistribution = amountToRedeem - marketingFeeDistribution;
        uint256 redeemAmount = amountToRedeem;

        marketingFeeRedeemed += marketingFeeDistribution;
        nitroFeeRedeemed += nitroFeeDistribution;
        totalFeeRedeemed += amountToRedeem;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), redeemAmount);
    
        emit AutoRedeem(marketingFeeDistribution, nitroFeeDistribution, redeemAmount, block.timestamp);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            marketingFeeDistribution,
            0,
            path,
            marketingReceiver,
            block.timestamp
        );

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            nitroFeeDistribution,
            0,
            path,
            nitroReceiver,
            block.timestamp
        );
    }

    /* Buyback */

    function triggerZeusBuyback(uint256 amount) external onlyOwner {
        buyTokens(amount, DEAD);
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        require(msg.sender != DEAD, "Buy Tokens: Dead address cannot call this function.");
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    /* ERC20 Standard */

    function name() external view virtual override returns (string memory) {
        return NAME;
    }
    
    function symbol() external view virtual override returns (string memory) {
        return SYMBOL;
    }
    
    function decimals() external view virtual override returns (uint8) {
        return DECIMALS;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address provider = msg.sender;
        return _transfer(provider, to, amount);
    }
    
    function allowance(address provider, address spender) public view virtual override returns (uint256) {
        return _allowances[provider][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address provider = msg.sender;
        _approve(provider, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        return _transfer(from, to, amount);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address provider = msg.sender;
        _approve(provider, spender, allowance(provider, spender) + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address provider = msg.sender;
        uint256 currentAllowance = allowance(provider, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(provider, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _approve(address provider, address spender, uint256 amount) internal virtual {
        require(provider != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[provider][spender] = amount;
        emit Approval(provider, spender, amount);
    }
    
    function _spendAllowance(address provider, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(provider, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(provider, spender, currentAllowance - amount);
            }
        }
    }

    /* Additional */

    function _basicTransfer(address from, address to, uint256 amount ) internal returns (bool) {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }
    
    /* Overrides */
 
    function _transfer(address from, address to, uint256 amount) internal virtual returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!tradeEnabled) {
            require(msg.sender == projectOwner || msg.sender == presaleFactory || msg.sender == owner() || msg.sender == presaleAddress, "ERC20: Only operator, owner or presale addresses can call this function since trading is not yet enabled.");

            if (from == owner()) {
                require(to != pair, "ERC20: Owner and operator are not allowed to sell if trading is not yet enabled.");
            }
        }

        if (inSwap || isExcludeFromFees[from]) {
            return _basicTransfer(from, to, amount);
        }

        if (from != pair && isSwapEnabled && totalFeeCollected - totalFeeRedeemed >= minSwap) {
            autoRedeem(minSwap);
        }

        uint256 newAmount = amount;

        if (isFeeActive && !isExcludeFromFees[from]) {
            newAmount = _beforeTokenTransfer(from, to, amount);
        }

        require(_balances[from] >= newAmount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = _balances[from] - newAmount;
            _balances[to] += newAmount;
        }

        emit Transfer(from, to, newAmount);

        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal swapping virtual returns (uint256) {
        if (from == pair && (buyMarketingFee + buyNitroFee > 0)) {
            return takeBuyFee(from, amount);
        }
        if (to == pair && (sellMarketingFee + sellNitroFee > 0)) {
            return takeSellFee(from, amount);
        }
        if (from != pair && to != pair && (transferMarketingFee + transferNitroFee > 0)) {
            return takeTransferFee(from, amount);
        }
        return amount;
    }

    /* Miscellaneous */

    function wTokens(IERC20 tokenAddress) external onlyOwner {
        require(address(this) != address(tokenAddress), "Cannot withdraw CBC token from this smart contract.");
        require(
            IERC20(tokenAddress).transfer(
                msg.sender,
                IERC20(tokenAddress).balanceOf(address(this))
            ),
            "WithdrawTokens: Transfer transaction might fail."
        );
    }

    function wNative() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function dropDifferentSpecificTokens(IERC20 tokenAddress, address[] memory recipients, uint256[] memory amount) external returns (bool) {
       for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0));
            require(IERC20(tokenAddress).transfer(recipients[i], amount[i]));
        }
        return true;
    }

    function dropSimilarSpecificTokens(IERC20 tokenAddress, address[] memory recipients, uint256 amount) external returns (bool) {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0));
            require(IERC20(tokenAddress).transfer(recipients[i], amount));
        }
        return true;
    }

    function dropDifferentSpecificNative(address[] memory recipients, uint256[] memory amount) external payable returns (bool) {
        uint256 total = 0;
        for(uint256 j = 0; j < amount.length; j++) {
            total = total + amount[j];
        }
        require(total <= msg.value, "Amount sent to be dropped is too low than total airdrop.");
        require(recipients.length == amount.length, "The length of recipient array is not equal to the length of native token airdrop array.");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Cannot transfer the airdrop native token to zero address.");
            payable(recipients[i]).transfer(amount[i]);
            emit NativeTransfer(recipients[i], amount[i]);
        }
        return true;
    }

    function dropSimilarSpecificNative(address[] memory recipients, uint256 amount) external payable returns (bool) {
        uint256 total = amount * recipients.length;
        require(total <= msg.value, "Amount sent to be dropped is too low than total airdrop.");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Cannot transfer the airdrop native token to zero address.");
            payable(recipients[i]).transfer(amount);
            emit NativeTransfer(recipients[i], amount);
        }
        return true;
    }

}
