// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JewelryLifecycle {
    // 定义珠宝的生命周期状态
    enum Status { MINED, POLISHED, GRADED, IN_STOCK, DESIGNED, SOLD }

    // 珠宝结构体定义
    struct Jewelry {
        uint256 id;                // 珠宝唯一ID
        uint256 CAId;              // 证书ID
        string description;        // 珠宝描述
        address currentOwner;      // 当前所有者
        Status status;             // 当前状态
        uint256 timestamp;         // 状态更新时间戳
    }

    uint256 public jewelryCount;                          // 珠宝总数
    mapping(uint256 => Jewelry) public jewelries;         // 珠宝映射

    // 角色地址
    address public miningCompany;
    address public cuttingCompany;
    address public gradingLab;
    address public jewelryMaker;

    // 事件定义
    event JewelryCreated(uint256 id, string description, address createdBy);
    event StatusUpdated(uint256 id, Status status, address updatedBy);
    event CertificateGenerated(uint256 id, uint256 CAId, address gradedBy);
    event OwnershipTransferred(uint256 id, address previousOwner, address newOwner);

    // 权限控制
    modifier onlyMiningCompany() { require(msg.sender == miningCompany, "Not authorized"); _; }
    modifier onlyCuttingCompany() { require(msg.sender == cuttingCompany, "Not authorized"); _; }
    modifier onlyGradingLab() { require(msg.sender == gradingLab, "Not authorized"); _; }
    modifier onlyJewelryMaker() { require(msg.sender == jewelryMaker, "Not authorized"); _; }

    // 设置角色
    function setRoles(
        address _miningCompany,
        address _cuttingCompany,
        address _gradingLab,
        address _jewelryMaker
    ) public {
        miningCompany = _miningCompany;
        cuttingCompany = _cuttingCompany;
        gradingLab = _gradingLab;
        jewelryMaker = _jewelryMaker;
    }

    // 创建珠宝（由开采公司调用）
    function createJewelry(string memory _description) public onlyMiningCompany {
        jewelryCount++;
        jewelries[jewelryCount] = Jewelry({
            id: jewelryCount,
            CAId: 0,
            description: _description,
            currentOwner: msg.sender,
            status: Status.MINED,
            timestamp: block.timestamp
        });
        emit JewelryCreated(jewelryCount, _description, msg.sender);
    }

    // 更新状态为 POLISHED（由加工公司调用）
    function updateStatusToPolished(uint256 _id) public onlyCuttingCompany {
        Jewelry storage jewelry = jewelries[_id];
        require(jewelry.status == Status.MINED, "Invalid state transition");
        jewelry.status = Status.POLISHED;
        jewelry.timestamp = block.timestamp;
        emit StatusUpdated(_id, Status.POLISHED, msg.sender);
    }

    // 生成证书并更新状态为 GRADED（由鉴定实验室调用）
    function generateCertificate(uint256 _id, uint256 _CAId) public onlyGradingLab {
        Jewelry storage jewelry = jewelries[_id];
        require(jewelry.status == Status.POLISHED, "Invalid state transition");
        require(jewelry.CAId == 0, "Certificate already generated");

        jewelry.CAId = _CAId;
        jewelry.status = Status.GRADED;
        jewelry.timestamp = block.timestamp;
        emit CertificateGenerated(_id, _CAId, msg.sender);
    }

    // 更新状态为 IN_STOCK（由珠宝制造商调用）
    function updateStatusToInStock(uint256 _id) public onlyJewelryMaker {
        Jewelry storage jewelry = jewelries[_id];
        require(jewelry.status == Status.GRADED, "Invalid state transition");
        jewelry.status = Status.IN_STOCK;
        jewelry.timestamp = block.timestamp;
        emit StatusUpdated(_id, Status.IN_STOCK, msg.sender);
    }

    // 更新状态为 DESIGNED（由珠宝制造商调用）
    function updateStatusToDesigned(uint256 _id) public onlyJewelryMaker {
        Jewelry storage jewelry = jewelries[_id];
        require(jewelry.status == Status.IN_STOCK, "Invalid state transition");
        jewelry.status = Status.DESIGNED;
        jewelry.timestamp = block.timestamp;
        emit StatusUpdated(_id, Status.DESIGNED, msg.sender);
    }

    // 转移所有权（由当前所有者调用）
    function transferOwnership(uint256 _id, address _newOwner) public {
        Jewelry storage jewelry = jewelries[_id];
        require(jewelry.currentOwner == msg.sender, "You are not the owner");
        require(_newOwner != address(0), "Invalid address");

        address previousOwner = jewelry.currentOwner;
        jewelry.currentOwner = _newOwner;
        jewelry.timestamp = block.timestamp;

        if (jewelry.status == Status.IN_STOCK || jewelry.status == Status.DESIGNED) {
            jewelry.status = Status.SOLD;
        }

        emit OwnershipTransferred(_id, previousOwner, _newOwner);
    }
}
