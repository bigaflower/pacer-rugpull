// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title HashStorage
 * @dev イーサリアムメインネット上のハッシュストレージコントラクト（ブロック番号をキーとしたマッピング方式）
 */
contract HashStorage {
    // アクセス制御用の変数
    address public admin;         // 管理者アドレス（保存・編集権限を持つ）
    address public superAdmin;    // スーパー管理者アドレス（管理者アドレスを変更できる）

    // ブロックハッシュエントリー（署名者アドレス付き）
    struct BlockHash {
        bytes32 hash;        // ハッシュ値
        uint256 updated;     // 登録・更新されたブロック番号（保存時のblock.number）
        address signer;      // 署名者アドレス（lottery-DOで署名に使用するアドレス）
    }

    // その他のハッシュエントリー（署名者アドレス無し）
    struct OtherHash {
        bytes32 hash;        // ハッシュ値
        uint256 updated;     // 登録・更新されたブロック番号（保存時のblock.number）
    }

    // 応募者ハッシュ（ブロック番号をキー）
    mapping(uint256 => BlockHash) public applicantHashes;

    // その他のハッシュ（任意キーを指定）
    mapping(bytes32 => OtherHash) public otherHashes;

    // イベント定義
    event ApplicantHashRegistered(uint256 indexed blockNumber, bytes32 hash, address signer, bool isUpdate, uint256 updatedAt);
    event OtherHashUpdated(bytes32 indexed key, bytes32 hash, uint256 blockNumber);
    event AdminChanged(address oldAdmin, address newAdmin);
    event SuperAdminChanged(address oldSuperAdmin, address newSuperAdmin);

    // コンストラクタ
    constructor(address _superadmin) {
        require(_superadmin != address(0), "Invalid super admin address");
        admin = msg.sender; // デプロイ時の呼び出し元を管理者に
        superAdmin = _superadmin;
    }

    // 管理者のみ許可
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    // スーパー管理者のみ許可
    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "Only super admin can call this function");
        _;
    }

    // =========== 応募者ハッシュ ===========

    /**
     * @dev ブロック番号をキーとして応募者ハッシュを登録・更新
     * @param blockNumber 対象のブロック番号
     * @param hash 登録・更新するハッシュ値
     * @param signer 署名者アドレス
     */
    function registerHash(uint256 blockNumber, bytes32 hash, address signer) external onlyAdmin {
        bool isUpdate = applicantHashes[blockNumber].updated != 0;

        applicantHashes[blockNumber] = BlockHash({
            hash: hash,
            updated: block.number,
            signer: signer
        });

        emit ApplicantHashRegistered(blockNumber, hash, signer, isUpdate, block.number);
    }

    /**
     * @dev 指定ブロック番号に対応する応募者ハッシュを取得
     * @param blockNumber 対象のブロック番号
     * @return hash ハッシュ値
     * @return updated 登録・更新されたブロック番号
     * @return signer 署名者アドレス
     */
    function getApplicantHash(uint256 blockNumber) external view returns (bytes32 hash, uint256 updated, address signer) {
        BlockHash storage entry = applicantHashes[blockNumber];
        require(entry.updated != 0, "No hash registered at this block");
        return (entry.hash, entry.updated, entry.signer);
    }

    // =========== その他のハッシュ ===========

    /**
     * @dev その他のハッシュを設定する（キー・バリュー形式）
     * @param key 任意のキー
     * @param hash ハッシュ値
     */
    function setOtherHash(bytes32 key, bytes32 hash) external onlyAdmin {
        otherHashes[key] = OtherHash({
            hash: hash,
            updated: block.number
        });

        emit OtherHashUpdated(key, hash, block.number);
    }

    /**
     * @dev その他のハッシュを取得
     * @param key 任意のキー
     * @return hash ハッシュ値
     * @return updated 登録・更新されたブロック番号
     */
    function getOtherHash(bytes32 key) external view returns (bytes32 hash, uint256 updated) {
        OtherHash storage entry = otherHashes[key];
        return (entry.hash, entry.updated);
    }

    // =========== 権限管理 ===========

    /**
     * @dev 管理者アドレスを変更（スーパー管理者のみ可能）
     * @param newAdmin 新しい管理者アドレス
     */
    function changeAdmin(address newAdmin) external onlySuperAdmin {
        require(newAdmin != address(0), "Invalid admin address");

        address oldAdmin = admin;
        admin = newAdmin;

        emit AdminChanged(oldAdmin, newAdmin);
    }

    /**
     * @dev スーパー管理者アドレスを変更（スーパー管理者のみ可能）
     * @param newSuperAdmin 新しいスーパー管理者アドレス
     */
    function changeSuperAdmin(address newSuperAdmin) external onlySuperAdmin {
        require(newSuperAdmin != address(0), "Invalid super admin address");

        address oldSuperAdmin = superAdmin;
        superAdmin = newSuperAdmin;

        emit SuperAdminChanged(oldSuperAdmin, newSuperAdmin);
    }
}
