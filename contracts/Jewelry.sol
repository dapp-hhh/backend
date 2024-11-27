// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JewelryLifecycle {
    // 定义珠宝的生命周期状态
    enum Status { MINED, POLISHED, GRADED, IN_STOCK, DESIGNED, SOLD }

    // 证书结构体定义
    struct Certificate {
        uint256 CAId;              // 证书ID
        string certificateURL;     // 存储证书的IPFS链接或外部URL
        uint256 issuedTimestamp;   // 证书发放时间戳
        address issuedBy;          // 颁发证书的地址（鉴定实验室）
        bytes signature;           // 证书签名
    }

    // 珠宝结构体定义
    struct Jewelry {
        uint256 id;                // 珠宝唯一ID
        Certificate certificate;   // 珠宝的证书信息
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
            certificate: Certificate(0, "", 0, address(0), ""), // 证书信息初始化为空
            description: _description,
            currentOwner: msg.sender,  // 当前所有者是开采公司
            status: Status.MINED,
            timestamp: block.timestamp
        });
        emit JewelryCreated(jewelryCount, _description, msg.sender);
    }

    // 更新状态为 POLISHED（由加工公司调用）
    function updateStatusToPolished(uint256 _id) public onlyCuttingCompany {
        Jewelry storage jewelry = jewelries[_id];
        require(jewelry.status == Status.MINED, "Invalid state transition");

        jewelry.currentOwner = msg.sender;  // 更新所有者为加工公司
        jewelry.status = Status.POLISHED;
        jewelry.timestamp = block.timestamp;
        emit StatusUpdated(_id, Status.POLISHED, msg.sender);
    }

    // 生成证书并更新状态为 GRADED（由鉴定实验室调用）
    function generateCertificate(uint256 _id, uint256 _CAId, string memory _certificateURL, bytes memory _signature) public onlyGradingLab {
        Jewelry storage jewelry = jewelries[_id];
        require(jewelry.status == Status.POLISHED, "Invalid state transition");
        require(jewelry.certificate.CAId == 0, "Certificate already generated");

        // 将证书信息存储到珠宝的结构体中
        jewelry.certificate = Certificate({
            CAId: _CAId,
            certificateURL: _certificateURL,
            issuedTimestamp: block.timestamp,
            issuedBy: msg.sender,  // 颁发证书的地址为鉴定实验室
            signature: _signature   // 存储签名
        });

        // 更新珠宝的状态为 GRADED
        jewelry.status = Status.GRADED;
        jewelry.timestamp = block.timestamp;
        emit CertificateGenerated(_id, _CAId, msg.sender);
    }

    // 获取所有珠宝信息（返回结构体数组）
    function getAllJewelry() public view returns (Jewelry[] memory) {
        Jewelry[] memory allJewelry = new Jewelry[](jewelryCount);
        for (uint256 i = 1; i <= jewelryCount; i++) {
            allJewelry[i - 1] = jewelries[i];
        }
        return allJewelry;
    }

    // 获取指定ID的珠宝信息
    function getJewelry(
        uint256 _id
    )
        public
        view
        returns (
            uint256 id,
            uint256 CAId,
            string memory certificateURL,
            uint256 issuedTimestamp,
            address issuedBy,
            bytes memory signature,
            string memory description,
            address currentOwner,
            Status status,
            uint256 timestamp
        )
    {
        Jewelry storage jewelry = jewelries[_id];
        return (
            jewelry.id,
            jewelry.certificate.CAId,
            jewelry.certificate.certificateURL,
            jewelry.certificate.issuedTimestamp,
            jewelry.certificate.issuedBy,
            jewelry.certificate.signature,
            jewelry.description,
            jewelry.currentOwner,
            jewelry.status,
            jewelry.timestamp
        );
    }

    // 更新状态为 IN_STOCK（由珠宝制造商调用）
    function updateStatusToInStock(uint256 _id) public onlyJewelryMaker {
        Jewelry storage jewelry = jewelries[_id];
        require(jewelry.status == Status.GRADED, "Invalid state transition");

        jewelry.currentOwner = msg.sender;  // 更新所有者为珠宝制造商
        jewelry.status = Status.IN_STOCK;
        jewelry.timestamp = block.timestamp;
        emit StatusUpdated(_id, Status.IN_STOCK, msg.sender);
    }

    // 更新状态为 DESIGNED（由珠宝制造商调用）
    function updateStatusToDesigned(uint256 _id) public onlyJewelryMaker {
        Jewelry storage jewelry = jewelries[_id];
        require(jewelry.status == Status.IN_STOCK, "Invalid state transition");

        jewelry.currentOwner = msg.sender;  // 更新所有者为珠宝制造商
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
        jewelry.currentOwner = _newOwner;  // 更新当前所有者为新所有者
        jewelry.timestamp = block.timestamp;

        // 如果珠宝状态是 IN_STOCK 或 DESIGNED，更新为 SOLD 状态
        if (jewelry.status == Status.IN_STOCK || jewelry.status == Status.DESIGNED) {
            jewelry.status = Status.SOLD;
        }

        emit OwnershipTransferred(_id, previousOwner, _newOwner);
    }

    // 验证证书签名
    function verifyCertificate(uint256 _id, bytes memory _signature) public view returns (string memory certificateURL, uint256 issuedTimestamp, address issuedBy, bool isValid) {
        Jewelry storage jewelry = jewelries[_id];
        require(jewelry.certificate.CAId != 0, "Certificate not found");

        // 计算消息的哈希值
        bytes32 messageHash = keccak256(abi.encodePacked(jewelry.certificate.CAId, jewelry.certificate.certificateURL, jewelry.certificate.issuedTimestamp, jewelry.certificate.issuedBy));

        // 恢复签名者的地址
        address signer = recoverSigner(messageHash, _signature);

        // 验证签名者是否为证书颁发者
        isValid = signer == jewelry.certificate.issuedBy;
        return (jewelry.certificate.certificateURL, jewelry.certificate.issuedTimestamp, jewelry.certificate.issuedBy, isValid);
    }

    // 恢复签名者地址
    function recoverSigner(bytes32 _messageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_messageHash, v, r, s);
    }

    // 拆分签名
    function splitSignature(bytes memory _sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}
