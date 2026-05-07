// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $LocalUsersTable extends LocalUsers
    with TableInfo<$LocalUsersTable, LocalUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passwordHashMeta =
      const VerificationMeta('passwordHash');
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
      'password_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _saltMeta = const VerificationMeta('salt');
  @override
  late final GeneratedColumn<String> salt = GeneratedColumn<String>(
      'salt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passwordHashVersionMeta =
      const VerificationMeta('passwordHashVersion');
  @override
  late final GeneratedColumn<int> passwordHashVersion = GeneratedColumn<int>(
      'password_hash_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        username,
        passwordHash,
        displayName,
        isActive,
        salt,
        passwordHashVersion,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_users';
  @override
  VerificationContext validateIntegrity(Insertable<LocalUser> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
          _passwordHashMeta,
          passwordHash.isAcceptableOrUnknown(
              data['password_hash']!, _passwordHashMeta));
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('salt')) {
      context.handle(
          _saltMeta, salt.isAcceptableOrUnknown(data['salt']!, _saltMeta));
    } else if (isInserting) {
      context.missing(_saltMeta);
    }
    if (data.containsKey('password_hash_version')) {
      context.handle(
          _passwordHashVersionMeta,
          passwordHashVersion.isAcceptableOrUnknown(
              data['password_hash_version']!, _passwordHashVersionMeta));
    } else if (isInserting) {
      context.missing(_passwordHashVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {username},
      ];
  @override
  LocalUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUser(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      passwordHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_hash'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      salt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}salt'])!,
      passwordHashVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}password_hash_version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalUsersTable createAlias(String alias) {
    return $LocalUsersTable(attachedDatabase, alias);
  }
}

class LocalUser extends DataClass implements Insertable<LocalUser> {
  final String id;
  final String username;
  final String passwordHash;
  final String? displayName;
  final bool isActive;
  final String salt;
  final int passwordHashVersion;
  final String createdAt;
  final String updatedAt;
  const LocalUser(
      {required this.id,
      required this.username,
      required this.passwordHash,
      this.displayName,
      required this.isActive,
      required this.salt,
      required this.passwordHashVersion,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    map['password_hash'] = Variable<String>(passwordHash);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['salt'] = Variable<String>(salt);
    map['password_hash_version'] = Variable<int>(passwordHashVersion);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  LocalUsersCompanion toCompanion(bool nullToAbsent) {
    return LocalUsersCompanion(
      id: Value(id),
      username: Value(username),
      passwordHash: Value(passwordHash),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      isActive: Value(isActive),
      salt: Value(salt),
      passwordHashVersion: Value(passwordHashVersion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalUser.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUser(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      salt: serializer.fromJson<String>(json['salt']),
      passwordHashVersion:
          serializer.fromJson<int>(json['passwordHashVersion']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'displayName': serializer.toJson<String?>(displayName),
      'isActive': serializer.toJson<bool>(isActive),
      'salt': serializer.toJson<String>(salt),
      'passwordHashVersion': serializer.toJson<int>(passwordHashVersion),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  LocalUser copyWith(
          {String? id,
          String? username,
          String? passwordHash,
          Value<String?> displayName = const Value.absent(),
          bool? isActive,
          String? salt,
          int? passwordHashVersion,
          String? createdAt,
          String? updatedAt}) =>
      LocalUser(
        id: id ?? this.id,
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
        displayName: displayName.present ? displayName.value : this.displayName,
        isActive: isActive ?? this.isActive,
        salt: salt ?? this.salt,
        passwordHashVersion: passwordHashVersion ?? this.passwordHashVersion,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalUser copyWithCompanion(LocalUsersCompanion data) {
    return LocalUser(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      salt: data.salt.present ? data.salt.value : this.salt,
      passwordHashVersion: data.passwordHashVersion.present
          ? data.passwordHashVersion.value
          : this.passwordHashVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUser(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('displayName: $displayName, ')
          ..write('isActive: $isActive, ')
          ..write('salt: $salt, ')
          ..write('passwordHashVersion: $passwordHashVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, username, passwordHash, displayName,
      isActive, salt, passwordHashVersion, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUser &&
          other.id == this.id &&
          other.username == this.username &&
          other.passwordHash == this.passwordHash &&
          other.displayName == this.displayName &&
          other.isActive == this.isActive &&
          other.salt == this.salt &&
          other.passwordHashVersion == this.passwordHashVersion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalUsersCompanion extends UpdateCompanion<LocalUser> {
  final Value<String> id;
  final Value<String> username;
  final Value<String> passwordHash;
  final Value<String?> displayName;
  final Value<bool> isActive;
  final Value<String> salt;
  final Value<int> passwordHashVersion;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const LocalUsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isActive = const Value.absent(),
    this.salt = const Value.absent(),
    this.passwordHashVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUsersCompanion.insert({
    required String id,
    required String username,
    required String passwordHash,
    this.displayName = const Value.absent(),
    this.isActive = const Value.absent(),
    required String salt,
    required int passwordHashVersion,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        username = Value(username),
        passwordHash = Value(passwordHash),
        salt = Value(salt),
        passwordHashVersion = Value(passwordHashVersion),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalUser> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? passwordHash,
    Expression<String>? displayName,
    Expression<bool>? isActive,
    Expression<String>? salt,
    Expression<int>? passwordHashVersion,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (displayName != null) 'display_name': displayName,
      if (isActive != null) 'is_active': isActive,
      if (salt != null) 'salt': salt,
      if (passwordHashVersion != null)
        'password_hash_version': passwordHashVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? username,
      Value<String>? passwordHash,
      Value<String?>? displayName,
      Value<bool>? isActive,
      Value<String>? salt,
      Value<int>? passwordHashVersion,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return LocalUsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
      salt: salt ?? this.salt,
      passwordHashVersion: passwordHashVersion ?? this.passwordHashVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (salt.present) {
      map['salt'] = Variable<String>(salt.value);
    }
    if (passwordHashVersion.present) {
      map['password_hash_version'] = Variable<int>(passwordHashVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('displayName: $displayName, ')
          ..write('isActive: $isActive, ')
          ..write('salt: $salt, ')
          ..write('passwordHashVersion: $passwordHashVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyMeta =
      const VerificationMeta('company');
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
      'company', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemNameMeta =
      const VerificationMeta('itemName');
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
      'item_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemCodeMeta =
      const VerificationMeta('itemCode');
  @override
  late final GeneratedColumn<String> itemCode = GeneratedColumn<String>(
      'item_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _buyingPriceExclTaxMeta =
      const VerificationMeta('buyingPriceExclTax');
  @override
  late final GeneratedColumn<String> buyingPriceExclTax =
      GeneratedColumn<String>('buying_price_excl_tax', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _buyingGstRateMeta =
      const VerificationMeta('buyingGstRate');
  @override
  late final GeneratedColumn<String> buyingGstRate = GeneratedColumn<String>(
      'buying_gst_rate', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _defaultSellingPriceExclTaxMeta =
      const VerificationMeta('defaultSellingPriceExclTax');
  @override
  late final GeneratedColumn<String> defaultSellingPriceExclTax =
      GeneratedColumn<String>(
          'default_selling_price_excl_tax', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _defaultGstRateMeta =
      const VerificationMeta('defaultGstRate');
  @override
  late final GeneratedColumn<String> defaultGstRate = GeneratedColumn<String>(
      'default_gst_rate', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityOnHandMeta =
      const VerificationMeta('quantityOnHand');
  @override
  late final GeneratedColumn<String> quantityOnHand = GeneratedColumn<String>(
      'quantity_on_hand', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lowStockThresholdMeta =
      const VerificationMeta('lowStockThreshold');
  @override
  late final GeneratedColumn<String> lowStockThreshold =
      GeneratedColumn<String>('low_stock_threshold', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        company,
        category,
        itemName,
        itemCode,
        buyingPriceExclTax,
        buyingGstRate,
        defaultSellingPriceExclTax,
        defaultGstRate,
        quantityOnHand,
        lowStockThreshold,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('company')) {
      context.handle(_companyMeta,
          company.isAcceptableOrUnknown(data['company']!, _companyMeta));
    } else if (isInserting) {
      context.missing(_companyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(_itemNameMeta,
          itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta));
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('item_code')) {
      context.handle(_itemCodeMeta,
          itemCode.isAcceptableOrUnknown(data['item_code']!, _itemCodeMeta));
    } else if (isInserting) {
      context.missing(_itemCodeMeta);
    }
    if (data.containsKey('buying_price_excl_tax')) {
      context.handle(
          _buyingPriceExclTaxMeta,
          buyingPriceExclTax.isAcceptableOrUnknown(
              data['buying_price_excl_tax']!, _buyingPriceExclTaxMeta));
    }
    if (data.containsKey('buying_gst_rate')) {
      context.handle(
          _buyingGstRateMeta,
          buyingGstRate.isAcceptableOrUnknown(
              data['buying_gst_rate']!, _buyingGstRateMeta));
    }
    if (data.containsKey('default_selling_price_excl_tax')) {
      context.handle(
          _defaultSellingPriceExclTaxMeta,
          defaultSellingPriceExclTax.isAcceptableOrUnknown(
              data['default_selling_price_excl_tax']!,
              _defaultSellingPriceExclTaxMeta));
    } else if (isInserting) {
      context.missing(_defaultSellingPriceExclTaxMeta);
    }
    if (data.containsKey('default_gst_rate')) {
      context.handle(
          _defaultGstRateMeta,
          defaultGstRate.isAcceptableOrUnknown(
              data['default_gst_rate']!, _defaultGstRateMeta));
    } else if (isInserting) {
      context.missing(_defaultGstRateMeta);
    }
    if (data.containsKey('quantity_on_hand')) {
      context.handle(
          _quantityOnHandMeta,
          quantityOnHand.isAcceptableOrUnknown(
              data['quantity_on_hand']!, _quantityOnHandMeta));
    } else if (isInserting) {
      context.missing(_quantityOnHandMeta);
    }
    if (data.containsKey('low_stock_threshold')) {
      context.handle(
          _lowStockThresholdMeta,
          lowStockThreshold.isAcceptableOrUnknown(
              data['low_stock_threshold']!, _lowStockThresholdMeta));
    } else if (isInserting) {
      context.missing(_lowStockThresholdMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {company, category, itemName},
        {itemCode},
      ];
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      company: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      itemName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_name'])!,
      itemCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_code'])!,
      buyingPriceExclTax: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}buying_price_excl_tax']),
      buyingGstRate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}buying_gst_rate']),
      defaultSellingPriceExclTax: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}default_selling_price_excl_tax'])!,
      defaultGstRate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}default_gst_rate'])!,
      quantityOnHand: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}quantity_on_hand'])!,
      lowStockThreshold: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}low_stock_threshold'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String company;
  final String category;
  final String itemName;
  final String itemCode;
  final String? buyingPriceExclTax;
  final String? buyingGstRate;
  final String defaultSellingPriceExclTax;
  final String defaultGstRate;
  final String quantityOnHand;
  final String lowStockThreshold;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  const Product(
      {required this.id,
      required this.company,
      required this.category,
      required this.itemName,
      required this.itemCode,
      this.buyingPriceExclTax,
      this.buyingGstRate,
      required this.defaultSellingPriceExclTax,
      required this.defaultGstRate,
      required this.quantityOnHand,
      required this.lowStockThreshold,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['company'] = Variable<String>(company);
    map['category'] = Variable<String>(category);
    map['item_name'] = Variable<String>(itemName);
    map['item_code'] = Variable<String>(itemCode);
    if (!nullToAbsent || buyingPriceExclTax != null) {
      map['buying_price_excl_tax'] = Variable<String>(buyingPriceExclTax);
    }
    if (!nullToAbsent || buyingGstRate != null) {
      map['buying_gst_rate'] = Variable<String>(buyingGstRate);
    }
    map['default_selling_price_excl_tax'] =
        Variable<String>(defaultSellingPriceExclTax);
    map['default_gst_rate'] = Variable<String>(defaultGstRate);
    map['quantity_on_hand'] = Variable<String>(quantityOnHand);
    map['low_stock_threshold'] = Variable<String>(lowStockThreshold);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      company: Value(company),
      category: Value(category),
      itemName: Value(itemName),
      itemCode: Value(itemCode),
      buyingPriceExclTax: buyingPriceExclTax == null && nullToAbsent
          ? const Value.absent()
          : Value(buyingPriceExclTax),
      buyingGstRate: buyingGstRate == null && nullToAbsent
          ? const Value.absent()
          : Value(buyingGstRate),
      defaultSellingPriceExclTax: Value(defaultSellingPriceExclTax),
      defaultGstRate: Value(defaultGstRate),
      quantityOnHand: Value(quantityOnHand),
      lowStockThreshold: Value(lowStockThreshold),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      company: serializer.fromJson<String>(json['company']),
      category: serializer.fromJson<String>(json['category']),
      itemName: serializer.fromJson<String>(json['itemName']),
      itemCode: serializer.fromJson<String>(json['itemCode']),
      buyingPriceExclTax:
          serializer.fromJson<String?>(json['buyingPriceExclTax']),
      buyingGstRate: serializer.fromJson<String?>(json['buyingGstRate']),
      defaultSellingPriceExclTax:
          serializer.fromJson<String>(json['defaultSellingPriceExclTax']),
      defaultGstRate: serializer.fromJson<String>(json['defaultGstRate']),
      quantityOnHand: serializer.fromJson<String>(json['quantityOnHand']),
      lowStockThreshold: serializer.fromJson<String>(json['lowStockThreshold']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'company': serializer.toJson<String>(company),
      'category': serializer.toJson<String>(category),
      'itemName': serializer.toJson<String>(itemName),
      'itemCode': serializer.toJson<String>(itemCode),
      'buyingPriceExclTax': serializer.toJson<String?>(buyingPriceExclTax),
      'buyingGstRate': serializer.toJson<String?>(buyingGstRate),
      'defaultSellingPriceExclTax':
          serializer.toJson<String>(defaultSellingPriceExclTax),
      'defaultGstRate': serializer.toJson<String>(defaultGstRate),
      'quantityOnHand': serializer.toJson<String>(quantityOnHand),
      'lowStockThreshold': serializer.toJson<String>(lowStockThreshold),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Product copyWith(
          {String? id,
          String? company,
          String? category,
          String? itemName,
          String? itemCode,
          Value<String?> buyingPriceExclTax = const Value.absent(),
          Value<String?> buyingGstRate = const Value.absent(),
          String? defaultSellingPriceExclTax,
          String? defaultGstRate,
          String? quantityOnHand,
          String? lowStockThreshold,
          bool? isActive,
          String? createdAt,
          String? updatedAt}) =>
      Product(
        id: id ?? this.id,
        company: company ?? this.company,
        category: category ?? this.category,
        itemName: itemName ?? this.itemName,
        itemCode: itemCode ?? this.itemCode,
        buyingPriceExclTax: buyingPriceExclTax.present
            ? buyingPriceExclTax.value
            : this.buyingPriceExclTax,
        buyingGstRate:
            buyingGstRate.present ? buyingGstRate.value : this.buyingGstRate,
        defaultSellingPriceExclTax:
            defaultSellingPriceExclTax ?? this.defaultSellingPriceExclTax,
        defaultGstRate: defaultGstRate ?? this.defaultGstRate,
        quantityOnHand: quantityOnHand ?? this.quantityOnHand,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      company: data.company.present ? data.company.value : this.company,
      category: data.category.present ? data.category.value : this.category,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      itemCode: data.itemCode.present ? data.itemCode.value : this.itemCode,
      buyingPriceExclTax: data.buyingPriceExclTax.present
          ? data.buyingPriceExclTax.value
          : this.buyingPriceExclTax,
      buyingGstRate: data.buyingGstRate.present
          ? data.buyingGstRate.value
          : this.buyingGstRate,
      defaultSellingPriceExclTax: data.defaultSellingPriceExclTax.present
          ? data.defaultSellingPriceExclTax.value
          : this.defaultSellingPriceExclTax,
      defaultGstRate: data.defaultGstRate.present
          ? data.defaultGstRate.value
          : this.defaultGstRate,
      quantityOnHand: data.quantityOnHand.present
          ? data.quantityOnHand.value
          : this.quantityOnHand,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('company: $company, ')
          ..write('category: $category, ')
          ..write('itemName: $itemName, ')
          ..write('itemCode: $itemCode, ')
          ..write('buyingPriceExclTax: $buyingPriceExclTax, ')
          ..write('buyingGstRate: $buyingGstRate, ')
          ..write('defaultSellingPriceExclTax: $defaultSellingPriceExclTax, ')
          ..write('defaultGstRate: $defaultGstRate, ')
          ..write('quantityOnHand: $quantityOnHand, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      company,
      category,
      itemName,
      itemCode,
      buyingPriceExclTax,
      buyingGstRate,
      defaultSellingPriceExclTax,
      defaultGstRate,
      quantityOnHand,
      lowStockThreshold,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.company == this.company &&
          other.category == this.category &&
          other.itemName == this.itemName &&
          other.itemCode == this.itemCode &&
          other.buyingPriceExclTax == this.buyingPriceExclTax &&
          other.buyingGstRate == this.buyingGstRate &&
          other.defaultSellingPriceExclTax == this.defaultSellingPriceExclTax &&
          other.defaultGstRate == this.defaultGstRate &&
          other.quantityOnHand == this.quantityOnHand &&
          other.lowStockThreshold == this.lowStockThreshold &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> company;
  final Value<String> category;
  final Value<String> itemName;
  final Value<String> itemCode;
  final Value<String?> buyingPriceExclTax;
  final Value<String?> buyingGstRate;
  final Value<String> defaultSellingPriceExclTax;
  final Value<String> defaultGstRate;
  final Value<String> quantityOnHand;
  final Value<String> lowStockThreshold;
  final Value<bool> isActive;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.company = const Value.absent(),
    this.category = const Value.absent(),
    this.itemName = const Value.absent(),
    this.itemCode = const Value.absent(),
    this.buyingPriceExclTax = const Value.absent(),
    this.buyingGstRate = const Value.absent(),
    this.defaultSellingPriceExclTax = const Value.absent(),
    this.defaultGstRate = const Value.absent(),
    this.quantityOnHand = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String company,
    required String category,
    required String itemName,
    required String itemCode,
    this.buyingPriceExclTax = const Value.absent(),
    this.buyingGstRate = const Value.absent(),
    required String defaultSellingPriceExclTax,
    required String defaultGstRate,
    required String quantityOnHand,
    required String lowStockThreshold,
    this.isActive = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        company = Value(company),
        category = Value(category),
        itemName = Value(itemName),
        itemCode = Value(itemCode),
        defaultSellingPriceExclTax = Value(defaultSellingPriceExclTax),
        defaultGstRate = Value(defaultGstRate),
        quantityOnHand = Value(quantityOnHand),
        lowStockThreshold = Value(lowStockThreshold),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? company,
    Expression<String>? category,
    Expression<String>? itemName,
    Expression<String>? itemCode,
    Expression<String>? buyingPriceExclTax,
    Expression<String>? buyingGstRate,
    Expression<String>? defaultSellingPriceExclTax,
    Expression<String>? defaultGstRate,
    Expression<String>? quantityOnHand,
    Expression<String>? lowStockThreshold,
    Expression<bool>? isActive,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (company != null) 'company': company,
      if (category != null) 'category': category,
      if (itemName != null) 'item_name': itemName,
      if (itemCode != null) 'item_code': itemCode,
      if (buyingPriceExclTax != null)
        'buying_price_excl_tax': buyingPriceExclTax,
      if (buyingGstRate != null) 'buying_gst_rate': buyingGstRate,
      if (defaultSellingPriceExclTax != null)
        'default_selling_price_excl_tax': defaultSellingPriceExclTax,
      if (defaultGstRate != null) 'default_gst_rate': defaultGstRate,
      if (quantityOnHand != null) 'quantity_on_hand': quantityOnHand,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? company,
      Value<String>? category,
      Value<String>? itemName,
      Value<String>? itemCode,
      Value<String?>? buyingPriceExclTax,
      Value<String?>? buyingGstRate,
      Value<String>? defaultSellingPriceExclTax,
      Value<String>? defaultGstRate,
      Value<String>? quantityOnHand,
      Value<String>? lowStockThreshold,
      Value<bool>? isActive,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      company: company ?? this.company,
      category: category ?? this.category,
      itemName: itemName ?? this.itemName,
      itemCode: itemCode ?? this.itemCode,
      buyingPriceExclTax: buyingPriceExclTax ?? this.buyingPriceExclTax,
      buyingGstRate: buyingGstRate ?? this.buyingGstRate,
      defaultSellingPriceExclTax:
          defaultSellingPriceExclTax ?? this.defaultSellingPriceExclTax,
      defaultGstRate: defaultGstRate ?? this.defaultGstRate,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (itemCode.present) {
      map['item_code'] = Variable<String>(itemCode.value);
    }
    if (buyingPriceExclTax.present) {
      map['buying_price_excl_tax'] = Variable<String>(buyingPriceExclTax.value);
    }
    if (buyingGstRate.present) {
      map['buying_gst_rate'] = Variable<String>(buyingGstRate.value);
    }
    if (defaultSellingPriceExclTax.present) {
      map['default_selling_price_excl_tax'] =
          Variable<String>(defaultSellingPriceExclTax.value);
    }
    if (defaultGstRate.present) {
      map['default_gst_rate'] = Variable<String>(defaultGstRate.value);
    }
    if (quantityOnHand.present) {
      map['quantity_on_hand'] = Variable<String>(quantityOnHand.value);
    }
    if (lowStockThreshold.present) {
      map['low_stock_threshold'] = Variable<String>(lowStockThreshold.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('company: $company, ')
          ..write('category: $category, ')
          ..write('itemName: $itemName, ')
          ..write('itemCode: $itemCode, ')
          ..write('buyingPriceExclTax: $buyingPriceExclTax, ')
          ..write('buyingGstRate: $buyingGstRate, ')
          ..write('defaultSellingPriceExclTax: $defaultSellingPriceExclTax, ')
          ..write('defaultGstRate: $defaultGstRate, ')
          ..write('quantityOnHand: $quantityOnHand, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SellersTable extends Sellers with TableInfo<$SellersTable, Seller> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SellersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stateCodeMeta =
      const VerificationMeta('stateCode');
  @override
  late final GeneratedColumn<String> stateCode = GeneratedColumn<String>(
      'state_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gstinMeta = const VerificationMeta('gstin');
  @override
  late final GeneratedColumn<String> gstin = GeneratedColumn<String>(
      'gstin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        address,
        state,
        stateCode,
        phone,
        gstin,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sellers';
  @override
  VerificationContext validateIntegrity(Insertable<Seller> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('state_code')) {
      context.handle(_stateCodeMeta,
          stateCode.isAcceptableOrUnknown(data['state_code']!, _stateCodeMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('gstin')) {
      context.handle(
          _gstinMeta, gstin.isAcceptableOrUnknown(data['gstin']!, _gstinMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {name, phone},
      ];
  @override
  Seller map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Seller(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state']),
      stateCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state_code']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      gstin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gstin']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SellersTable createAlias(String alias) {
    return $SellersTable(attachedDatabase, alias);
  }
}

class Seller extends DataClass implements Insertable<Seller> {
  final String id;
  final String name;
  final String address;
  final String? state;
  final String? stateCode;
  final String? phone;
  final String? gstin;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  const Seller(
      {required this.id,
      required this.name,
      required this.address,
      this.state,
      this.stateCode,
      this.phone,
      this.gstin,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || stateCode != null) {
      map['state_code'] = Variable<String>(stateCode);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || gstin != null) {
      map['gstin'] = Variable<String>(gstin);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SellersCompanion toCompanion(bool nullToAbsent) {
    return SellersCompanion(
      id: Value(id),
      name: Value(name),
      address: Value(address),
      state:
          state == null && nullToAbsent ? const Value.absent() : Value(state),
      stateCode: stateCode == null && nullToAbsent
          ? const Value.absent()
          : Value(stateCode),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      gstin:
          gstin == null && nullToAbsent ? const Value.absent() : Value(gstin),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Seller.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Seller(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      state: serializer.fromJson<String?>(json['state']),
      stateCode: serializer.fromJson<String?>(json['stateCode']),
      phone: serializer.fromJson<String?>(json['phone']),
      gstin: serializer.fromJson<String?>(json['gstin']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'state': serializer.toJson<String?>(state),
      'stateCode': serializer.toJson<String?>(stateCode),
      'phone': serializer.toJson<String?>(phone),
      'gstin': serializer.toJson<String?>(gstin),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Seller copyWith(
          {String? id,
          String? name,
          String? address,
          Value<String?> state = const Value.absent(),
          Value<String?> stateCode = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> gstin = const Value.absent(),
          bool? isActive,
          String? createdAt,
          String? updatedAt}) =>
      Seller(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        state: state.present ? state.value : this.state,
        stateCode: stateCode.present ? stateCode.value : this.stateCode,
        phone: phone.present ? phone.value : this.phone,
        gstin: gstin.present ? gstin.value : this.gstin,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Seller copyWithCompanion(SellersCompanion data) {
    return Seller(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      state: data.state.present ? data.state.value : this.state,
      stateCode: data.stateCode.present ? data.stateCode.value : this.stateCode,
      phone: data.phone.present ? data.phone.value : this.phone,
      gstin: data.gstin.present ? data.gstin.value : this.gstin,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Seller(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('state: $state, ')
          ..write('stateCode: $stateCode, ')
          ..write('phone: $phone, ')
          ..write('gstin: $gstin, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, address, state, stateCode, phone,
      gstin, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Seller &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.state == this.state &&
          other.stateCode == this.stateCode &&
          other.phone == this.phone &&
          other.gstin == this.gstin &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SellersCompanion extends UpdateCompanion<Seller> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> address;
  final Value<String?> state;
  final Value<String?> stateCode;
  final Value<String?> phone;
  final Value<String?> gstin;
  final Value<bool> isActive;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const SellersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.state = const Value.absent(),
    this.stateCode = const Value.absent(),
    this.phone = const Value.absent(),
    this.gstin = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SellersCompanion.insert({
    required String id,
    required String name,
    required String address,
    this.state = const Value.absent(),
    this.stateCode = const Value.absent(),
    this.phone = const Value.absent(),
    this.gstin = const Value.absent(),
    this.isActive = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        address = Value(address),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Seller> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? state,
    Expression<String>? stateCode,
    Expression<String>? phone,
    Expression<String>? gstin,
    Expression<bool>? isActive,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (state != null) 'state': state,
      if (stateCode != null) 'state_code': stateCode,
      if (phone != null) 'phone': phone,
      if (gstin != null) 'gstin': gstin,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SellersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? address,
      Value<String?>? state,
      Value<String?>? stateCode,
      Value<String?>? phone,
      Value<String?>? gstin,
      Value<bool>? isActive,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return SellersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (stateCode.present) {
      map['state_code'] = Variable<String>(stateCode.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (gstin.present) {
      map['gstin'] = Variable<String>(gstin.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SellersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('state: $state, ')
          ..write('stateCode: $stateCode, ')
          ..write('phone: $phone, ')
          ..write('gstin: $gstin, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices with TableInfo<$InvoicesTable, Invoice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestIdMeta =
      const VerificationMeta('requestId');
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
      'request_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestHashMeta =
      const VerificationMeta('requestHash');
  @override
  late final GeneratedColumn<String> requestHash = GeneratedColumn<String>(
      'request_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _invoiceNumberMeta =
      const VerificationMeta('invoiceNumber');
  @override
  late final GeneratedColumn<int> invoiceNumber = GeneratedColumn<int>(
      'invoice_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sellerIdMeta =
      const VerificationMeta('sellerId');
  @override
  late final GeneratedColumn<String> sellerId = GeneratedColumn<String>(
      'seller_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sellers (id)'));
  static const VerificationMeta _sellerNameMeta =
      const VerificationMeta('sellerName');
  @override
  late final GeneratedColumn<String> sellerName = GeneratedColumn<String>(
      'seller_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sellerAddressMeta =
      const VerificationMeta('sellerAddress');
  @override
  late final GeneratedColumn<String> sellerAddress = GeneratedColumn<String>(
      'seller_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sellerStateMeta =
      const VerificationMeta('sellerState');
  @override
  late final GeneratedColumn<String> sellerState = GeneratedColumn<String>(
      'seller_state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sellerStateCodeMeta =
      const VerificationMeta('sellerStateCode');
  @override
  late final GeneratedColumn<String> sellerStateCode = GeneratedColumn<String>(
      'seller_state_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sellerPhoneMeta =
      const VerificationMeta('sellerPhone');
  @override
  late final GeneratedColumn<String> sellerPhone = GeneratedColumn<String>(
      'seller_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sellerGstinMeta =
      const VerificationMeta('sellerGstin');
  @override
  late final GeneratedColumn<String> sellerGstin = GeneratedColumn<String>(
      'seller_gstin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _placeOfSupplyStateMeta =
      const VerificationMeta('placeOfSupplyState');
  @override
  late final GeneratedColumn<String> placeOfSupplyState =
      GeneratedColumn<String>('place_of_supply_state', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _placeOfSupplyStateCodeMeta =
      const VerificationMeta('placeOfSupplyStateCode');
  @override
  late final GeneratedColumn<String> placeOfSupplyStateCode =
      GeneratedColumn<String>('place_of_supply_state_code', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyNameMeta =
      const VerificationMeta('companyName');
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
      'company_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyAddressMeta =
      const VerificationMeta('companyAddress');
  @override
  late final GeneratedColumn<String> companyAddress = GeneratedColumn<String>(
      'company_address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyCityMeta =
      const VerificationMeta('companyCity');
  @override
  late final GeneratedColumn<String> companyCity = GeneratedColumn<String>(
      'company_city', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyStateMeta =
      const VerificationMeta('companyState');
  @override
  late final GeneratedColumn<String> companyState = GeneratedColumn<String>(
      'company_state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyStateCodeMeta =
      const VerificationMeta('companyStateCode');
  @override
  late final GeneratedColumn<String> companyStateCode = GeneratedColumn<String>(
      'company_state_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyGstinMeta =
      const VerificationMeta('companyGstin');
  @override
  late final GeneratedColumn<String> companyGstin = GeneratedColumn<String>(
      'company_gstin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyPhoneMeta =
      const VerificationMeta('companyPhone');
  @override
  late final GeneratedColumn<String> companyPhone = GeneratedColumn<String>(
      'company_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyEmailMeta =
      const VerificationMeta('companyEmail');
  @override
  late final GeneratedColumn<String> companyEmail = GeneratedColumn<String>(
      'company_email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyBankNameMeta =
      const VerificationMeta('companyBankName');
  @override
  late final GeneratedColumn<String> companyBankName = GeneratedColumn<String>(
      'company_bank_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyBankAccountMeta =
      const VerificationMeta('companyBankAccount');
  @override
  late final GeneratedColumn<String> companyBankAccount =
      GeneratedColumn<String>('company_bank_account', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyBankIfscMeta =
      const VerificationMeta('companyBankIfsc');
  @override
  late final GeneratedColumn<String> companyBankIfsc = GeneratedColumn<String>(
      'company_bank_ifsc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyBankBranchMeta =
      const VerificationMeta('companyBankBranch');
  @override
  late final GeneratedColumn<String> companyBankBranch =
      GeneratedColumn<String>('company_bank_branch', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyJurisdictionMeta =
      const VerificationMeta('companyJurisdiction');
  @override
  late final GeneratedColumn<String> companyJurisdiction =
      GeneratedColumn<String>('company_jurisdiction', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _invoiceDateMeta =
      const VerificationMeta('invoiceDate');
  @override
  late final GeneratedColumn<String> invoiceDate = GeneratedColumn<String>(
      'invoice_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taxRegimeMeta =
      const VerificationMeta('taxRegime');
  @override
  late final GeneratedColumn<String> taxRegime = GeneratedColumn<String>(
      'tax_regime', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _paymentModeMeta =
      const VerificationMeta('paymentMode');
  @override
  late final GeneratedColumn<String> paymentMode = GeneratedColumn<String>(
      'payment_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<String> subtotal = GeneratedColumn<String>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _discountTotalMeta =
      const VerificationMeta('discountTotal');
  @override
  late final GeneratedColumn<String> discountTotal = GeneratedColumn<String>(
      'discount_total', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taxableTotalMeta =
      const VerificationMeta('taxableTotal');
  @override
  late final GeneratedColumn<String> taxableTotal = GeneratedColumn<String>(
      'taxable_total', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gstTotalMeta =
      const VerificationMeta('gstTotal');
  @override
  late final GeneratedColumn<String> gstTotal = GeneratedColumn<String>(
      'gst_total', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _grandTotalMeta =
      const VerificationMeta('grandTotal');
  @override
  late final GeneratedColumn<String> grandTotal = GeneratedColumn<String>(
      'grand_total', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
      'created_by_user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES local_users (id)'));
  static const VerificationMeta _cancelRequestIdMeta =
      const VerificationMeta('cancelRequestId');
  @override
  late final GeneratedColumn<String> cancelRequestId = GeneratedColumn<String>(
      'cancel_request_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cancelRequestHashMeta =
      const VerificationMeta('cancelRequestHash');
  @override
  late final GeneratedColumn<String> cancelRequestHash =
      GeneratedColumn<String>('cancel_request_hash', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _canceledByUserIdMeta =
      const VerificationMeta('canceledByUserId');
  @override
  late final GeneratedColumn<String> canceledByUserId = GeneratedColumn<String>(
      'canceled_by_user_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES local_users (id)'));
  static const VerificationMeta _cancelReasonMeta =
      const VerificationMeta('cancelReason');
  @override
  late final GeneratedColumn<String> cancelReason = GeneratedColumn<String>(
      'cancel_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _canceledAtMeta =
      const VerificationMeta('canceledAt');
  @override
  late final GeneratedColumn<String> canceledAt = GeneratedColumn<String>(
      'canceled_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        requestId,
        requestHash,
        invoiceNumber,
        sellerId,
        sellerName,
        sellerAddress,
        sellerState,
        sellerStateCode,
        sellerPhone,
        sellerGstin,
        placeOfSupplyState,
        placeOfSupplyStateCode,
        companyName,
        companyAddress,
        companyCity,
        companyState,
        companyStateCode,
        companyGstin,
        companyPhone,
        companyEmail,
        companyBankName,
        companyBankAccount,
        companyBankIfsc,
        companyBankBranch,
        companyJurisdiction,
        invoiceDate,
        taxRegime,
        status,
        paymentMode,
        subtotal,
        discountTotal,
        taxableTotal,
        gstTotal,
        grandTotal,
        notes,
        createdByUserId,
        cancelRequestId,
        cancelRequestHash,
        canceledByUserId,
        cancelReason,
        canceledAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(Insertable<Invoice> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('request_id')) {
      context.handle(_requestIdMeta,
          requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta));
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('request_hash')) {
      context.handle(
          _requestHashMeta,
          requestHash.isAcceptableOrUnknown(
              data['request_hash']!, _requestHashMeta));
    } else if (isInserting) {
      context.missing(_requestHashMeta);
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
          _invoiceNumberMeta,
          invoiceNumber.isAcceptableOrUnknown(
              data['invoice_number']!, _invoiceNumberMeta));
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('seller_id')) {
      context.handle(_sellerIdMeta,
          sellerId.isAcceptableOrUnknown(data['seller_id']!, _sellerIdMeta));
    } else if (isInserting) {
      context.missing(_sellerIdMeta);
    }
    if (data.containsKey('seller_name')) {
      context.handle(
          _sellerNameMeta,
          sellerName.isAcceptableOrUnknown(
              data['seller_name']!, _sellerNameMeta));
    } else if (isInserting) {
      context.missing(_sellerNameMeta);
    }
    if (data.containsKey('seller_address')) {
      context.handle(
          _sellerAddressMeta,
          sellerAddress.isAcceptableOrUnknown(
              data['seller_address']!, _sellerAddressMeta));
    } else if (isInserting) {
      context.missing(_sellerAddressMeta);
    }
    if (data.containsKey('seller_state')) {
      context.handle(
          _sellerStateMeta,
          sellerState.isAcceptableOrUnknown(
              data['seller_state']!, _sellerStateMeta));
    }
    if (data.containsKey('seller_state_code')) {
      context.handle(
          _sellerStateCodeMeta,
          sellerStateCode.isAcceptableOrUnknown(
              data['seller_state_code']!, _sellerStateCodeMeta));
    }
    if (data.containsKey('seller_phone')) {
      context.handle(
          _sellerPhoneMeta,
          sellerPhone.isAcceptableOrUnknown(
              data['seller_phone']!, _sellerPhoneMeta));
    }
    if (data.containsKey('seller_gstin')) {
      context.handle(
          _sellerGstinMeta,
          sellerGstin.isAcceptableOrUnknown(
              data['seller_gstin']!, _sellerGstinMeta));
    }
    if (data.containsKey('place_of_supply_state')) {
      context.handle(
          _placeOfSupplyStateMeta,
          placeOfSupplyState.isAcceptableOrUnknown(
              data['place_of_supply_state']!, _placeOfSupplyStateMeta));
    } else if (isInserting) {
      context.missing(_placeOfSupplyStateMeta);
    }
    if (data.containsKey('place_of_supply_state_code')) {
      context.handle(
          _placeOfSupplyStateCodeMeta,
          placeOfSupplyStateCode.isAcceptableOrUnknown(
              data['place_of_supply_state_code']!,
              _placeOfSupplyStateCodeMeta));
    } else if (isInserting) {
      context.missing(_placeOfSupplyStateCodeMeta);
    }
    if (data.containsKey('company_name')) {
      context.handle(
          _companyNameMeta,
          companyName.isAcceptableOrUnknown(
              data['company_name']!, _companyNameMeta));
    } else if (isInserting) {
      context.missing(_companyNameMeta);
    }
    if (data.containsKey('company_address')) {
      context.handle(
          _companyAddressMeta,
          companyAddress.isAcceptableOrUnknown(
              data['company_address']!, _companyAddressMeta));
    } else if (isInserting) {
      context.missing(_companyAddressMeta);
    }
    if (data.containsKey('company_city')) {
      context.handle(
          _companyCityMeta,
          companyCity.isAcceptableOrUnknown(
              data['company_city']!, _companyCityMeta));
    } else if (isInserting) {
      context.missing(_companyCityMeta);
    }
    if (data.containsKey('company_state')) {
      context.handle(
          _companyStateMeta,
          companyState.isAcceptableOrUnknown(
              data['company_state']!, _companyStateMeta));
    } else if (isInserting) {
      context.missing(_companyStateMeta);
    }
    if (data.containsKey('company_state_code')) {
      context.handle(
          _companyStateCodeMeta,
          companyStateCode.isAcceptableOrUnknown(
              data['company_state_code']!, _companyStateCodeMeta));
    } else if (isInserting) {
      context.missing(_companyStateCodeMeta);
    }
    if (data.containsKey('company_gstin')) {
      context.handle(
          _companyGstinMeta,
          companyGstin.isAcceptableOrUnknown(
              data['company_gstin']!, _companyGstinMeta));
    }
    if (data.containsKey('company_phone')) {
      context.handle(
          _companyPhoneMeta,
          companyPhone.isAcceptableOrUnknown(
              data['company_phone']!, _companyPhoneMeta));
    }
    if (data.containsKey('company_email')) {
      context.handle(
          _companyEmailMeta,
          companyEmail.isAcceptableOrUnknown(
              data['company_email']!, _companyEmailMeta));
    }
    if (data.containsKey('company_bank_name')) {
      context.handle(
          _companyBankNameMeta,
          companyBankName.isAcceptableOrUnknown(
              data['company_bank_name']!, _companyBankNameMeta));
    }
    if (data.containsKey('company_bank_account')) {
      context.handle(
          _companyBankAccountMeta,
          companyBankAccount.isAcceptableOrUnknown(
              data['company_bank_account']!, _companyBankAccountMeta));
    }
    if (data.containsKey('company_bank_ifsc')) {
      context.handle(
          _companyBankIfscMeta,
          companyBankIfsc.isAcceptableOrUnknown(
              data['company_bank_ifsc']!, _companyBankIfscMeta));
    }
    if (data.containsKey('company_bank_branch')) {
      context.handle(
          _companyBankBranchMeta,
          companyBankBranch.isAcceptableOrUnknown(
              data['company_bank_branch']!, _companyBankBranchMeta));
    }
    if (data.containsKey('company_jurisdiction')) {
      context.handle(
          _companyJurisdictionMeta,
          companyJurisdiction.isAcceptableOrUnknown(
              data['company_jurisdiction']!, _companyJurisdictionMeta));
    }
    if (data.containsKey('invoice_date')) {
      context.handle(
          _invoiceDateMeta,
          invoiceDate.isAcceptableOrUnknown(
              data['invoice_date']!, _invoiceDateMeta));
    } else if (isInserting) {
      context.missing(_invoiceDateMeta);
    }
    if (data.containsKey('tax_regime')) {
      context.handle(_taxRegimeMeta,
          taxRegime.isAcceptableOrUnknown(data['tax_regime']!, _taxRegimeMeta));
    } else if (isInserting) {
      context.missing(_taxRegimeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('payment_mode')) {
      context.handle(
          _paymentModeMeta,
          paymentMode.isAcceptableOrUnknown(
              data['payment_mode']!, _paymentModeMeta));
    } else if (isInserting) {
      context.missing(_paymentModeMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('discount_total')) {
      context.handle(
          _discountTotalMeta,
          discountTotal.isAcceptableOrUnknown(
              data['discount_total']!, _discountTotalMeta));
    } else if (isInserting) {
      context.missing(_discountTotalMeta);
    }
    if (data.containsKey('taxable_total')) {
      context.handle(
          _taxableTotalMeta,
          taxableTotal.isAcceptableOrUnknown(
              data['taxable_total']!, _taxableTotalMeta));
    } else if (isInserting) {
      context.missing(_taxableTotalMeta);
    }
    if (data.containsKey('gst_total')) {
      context.handle(_gstTotalMeta,
          gstTotal.isAcceptableOrUnknown(data['gst_total']!, _gstTotalMeta));
    } else if (isInserting) {
      context.missing(_gstTotalMeta);
    }
    if (data.containsKey('grand_total')) {
      context.handle(
          _grandTotalMeta,
          grandTotal.isAcceptableOrUnknown(
              data['grand_total']!, _grandTotalMeta));
    } else if (isInserting) {
      context.missing(_grandTotalMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('cancel_request_id')) {
      context.handle(
          _cancelRequestIdMeta,
          cancelRequestId.isAcceptableOrUnknown(
              data['cancel_request_id']!, _cancelRequestIdMeta));
    }
    if (data.containsKey('cancel_request_hash')) {
      context.handle(
          _cancelRequestHashMeta,
          cancelRequestHash.isAcceptableOrUnknown(
              data['cancel_request_hash']!, _cancelRequestHashMeta));
    }
    if (data.containsKey('canceled_by_user_id')) {
      context.handle(
          _canceledByUserIdMeta,
          canceledByUserId.isAcceptableOrUnknown(
              data['canceled_by_user_id']!, _canceledByUserIdMeta));
    }
    if (data.containsKey('cancel_reason')) {
      context.handle(
          _cancelReasonMeta,
          cancelReason.isAcceptableOrUnknown(
              data['cancel_reason']!, _cancelReasonMeta));
    }
    if (data.containsKey('canceled_at')) {
      context.handle(
          _canceledAtMeta,
          canceledAt.isAcceptableOrUnknown(
              data['canceled_at']!, _canceledAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Invoice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Invoice(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      requestId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_id'])!,
      requestHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_hash'])!,
      invoiceNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}invoice_number'])!,
      sellerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seller_id'])!,
      sellerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seller_name'])!,
      sellerAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seller_address'])!,
      sellerState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seller_state']),
      sellerStateCode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}seller_state_code']),
      sellerPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seller_phone']),
      sellerGstin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seller_gstin']),
      placeOfSupplyState: attachedDatabase.typeMapping.read(DriftSqlType.string,
          data['${effectivePrefix}place_of_supply_state'])!,
      placeOfSupplyStateCode: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}place_of_supply_state_code'])!,
      companyName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_name'])!,
      companyAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}company_address'])!,
      companyCity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_city'])!,
      companyState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_state'])!,
      companyStateCode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}company_state_code'])!,
      companyGstin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_gstin']),
      companyPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_phone']),
      companyEmail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company_email']),
      companyBankName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}company_bank_name']),
      companyBankAccount: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}company_bank_account']),
      companyBankIfsc: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}company_bank_ifsc']),
      companyBankBranch: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}company_bank_branch']),
      companyJurisdiction: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}company_jurisdiction']),
      invoiceDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_date'])!,
      taxRegime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tax_regime'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      paymentMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_mode'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtotal'])!,
      discountTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}discount_total'])!,
      taxableTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}taxable_total'])!,
      gstTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gst_total'])!,
      grandTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}grand_total'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}created_by_user_id'])!,
      cancelRequestId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}cancel_request_id']),
      cancelRequestHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}cancel_request_hash']),
      canceledByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}canceled_by_user_id']),
      cancelReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cancel_reason']),
      canceledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}canceled_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class Invoice extends DataClass implements Insertable<Invoice> {
  final String id;
  final String requestId;
  final String requestHash;
  final int invoiceNumber;
  final String sellerId;
  final String sellerName;
  final String sellerAddress;
  final String? sellerState;
  final String? sellerStateCode;
  final String? sellerPhone;
  final String? sellerGstin;
  final String placeOfSupplyState;
  final String placeOfSupplyStateCode;
  final String companyName;
  final String companyAddress;
  final String companyCity;
  final String companyState;
  final String companyStateCode;
  final String? companyGstin;
  final String? companyPhone;
  final String? companyEmail;
  final String? companyBankName;
  final String? companyBankAccount;
  final String? companyBankIfsc;
  final String? companyBankBranch;
  final String? companyJurisdiction;
  final String invoiceDate;
  final String taxRegime;
  final String status;
  final String paymentMode;
  final String subtotal;
  final String discountTotal;
  final String taxableTotal;
  final String gstTotal;
  final String grandTotal;
  final String? notes;
  final String createdByUserId;
  final String? cancelRequestId;
  final String? cancelRequestHash;
  final String? canceledByUserId;
  final String? cancelReason;
  final String? canceledAt;
  final String createdAt;
  const Invoice(
      {required this.id,
      required this.requestId,
      required this.requestHash,
      required this.invoiceNumber,
      required this.sellerId,
      required this.sellerName,
      required this.sellerAddress,
      this.sellerState,
      this.sellerStateCode,
      this.sellerPhone,
      this.sellerGstin,
      required this.placeOfSupplyState,
      required this.placeOfSupplyStateCode,
      required this.companyName,
      required this.companyAddress,
      required this.companyCity,
      required this.companyState,
      required this.companyStateCode,
      this.companyGstin,
      this.companyPhone,
      this.companyEmail,
      this.companyBankName,
      this.companyBankAccount,
      this.companyBankIfsc,
      this.companyBankBranch,
      this.companyJurisdiction,
      required this.invoiceDate,
      required this.taxRegime,
      required this.status,
      required this.paymentMode,
      required this.subtotal,
      required this.discountTotal,
      required this.taxableTotal,
      required this.gstTotal,
      required this.grandTotal,
      this.notes,
      required this.createdByUserId,
      this.cancelRequestId,
      this.cancelRequestHash,
      this.canceledByUserId,
      this.cancelReason,
      this.canceledAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['request_id'] = Variable<String>(requestId);
    map['request_hash'] = Variable<String>(requestHash);
    map['invoice_number'] = Variable<int>(invoiceNumber);
    map['seller_id'] = Variable<String>(sellerId);
    map['seller_name'] = Variable<String>(sellerName);
    map['seller_address'] = Variable<String>(sellerAddress);
    if (!nullToAbsent || sellerState != null) {
      map['seller_state'] = Variable<String>(sellerState);
    }
    if (!nullToAbsent || sellerStateCode != null) {
      map['seller_state_code'] = Variable<String>(sellerStateCode);
    }
    if (!nullToAbsent || sellerPhone != null) {
      map['seller_phone'] = Variable<String>(sellerPhone);
    }
    if (!nullToAbsent || sellerGstin != null) {
      map['seller_gstin'] = Variable<String>(sellerGstin);
    }
    map['place_of_supply_state'] = Variable<String>(placeOfSupplyState);
    map['place_of_supply_state_code'] =
        Variable<String>(placeOfSupplyStateCode);
    map['company_name'] = Variable<String>(companyName);
    map['company_address'] = Variable<String>(companyAddress);
    map['company_city'] = Variable<String>(companyCity);
    map['company_state'] = Variable<String>(companyState);
    map['company_state_code'] = Variable<String>(companyStateCode);
    if (!nullToAbsent || companyGstin != null) {
      map['company_gstin'] = Variable<String>(companyGstin);
    }
    if (!nullToAbsent || companyPhone != null) {
      map['company_phone'] = Variable<String>(companyPhone);
    }
    if (!nullToAbsent || companyEmail != null) {
      map['company_email'] = Variable<String>(companyEmail);
    }
    if (!nullToAbsent || companyBankName != null) {
      map['company_bank_name'] = Variable<String>(companyBankName);
    }
    if (!nullToAbsent || companyBankAccount != null) {
      map['company_bank_account'] = Variable<String>(companyBankAccount);
    }
    if (!nullToAbsent || companyBankIfsc != null) {
      map['company_bank_ifsc'] = Variable<String>(companyBankIfsc);
    }
    if (!nullToAbsent || companyBankBranch != null) {
      map['company_bank_branch'] = Variable<String>(companyBankBranch);
    }
    if (!nullToAbsent || companyJurisdiction != null) {
      map['company_jurisdiction'] = Variable<String>(companyJurisdiction);
    }
    map['invoice_date'] = Variable<String>(invoiceDate);
    map['tax_regime'] = Variable<String>(taxRegime);
    map['status'] = Variable<String>(status);
    map['payment_mode'] = Variable<String>(paymentMode);
    map['subtotal'] = Variable<String>(subtotal);
    map['discount_total'] = Variable<String>(discountTotal);
    map['taxable_total'] = Variable<String>(taxableTotal);
    map['gst_total'] = Variable<String>(gstTotal);
    map['grand_total'] = Variable<String>(grandTotal);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    if (!nullToAbsent || cancelRequestId != null) {
      map['cancel_request_id'] = Variable<String>(cancelRequestId);
    }
    if (!nullToAbsent || cancelRequestHash != null) {
      map['cancel_request_hash'] = Variable<String>(cancelRequestHash);
    }
    if (!nullToAbsent || canceledByUserId != null) {
      map['canceled_by_user_id'] = Variable<String>(canceledByUserId);
    }
    if (!nullToAbsent || cancelReason != null) {
      map['cancel_reason'] = Variable<String>(cancelReason);
    }
    if (!nullToAbsent || canceledAt != null) {
      map['canceled_at'] = Variable<String>(canceledAt);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      requestId: Value(requestId),
      requestHash: Value(requestHash),
      invoiceNumber: Value(invoiceNumber),
      sellerId: Value(sellerId),
      sellerName: Value(sellerName),
      sellerAddress: Value(sellerAddress),
      sellerState: sellerState == null && nullToAbsent
          ? const Value.absent()
          : Value(sellerState),
      sellerStateCode: sellerStateCode == null && nullToAbsent
          ? const Value.absent()
          : Value(sellerStateCode),
      sellerPhone: sellerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(sellerPhone),
      sellerGstin: sellerGstin == null && nullToAbsent
          ? const Value.absent()
          : Value(sellerGstin),
      placeOfSupplyState: Value(placeOfSupplyState),
      placeOfSupplyStateCode: Value(placeOfSupplyStateCode),
      companyName: Value(companyName),
      companyAddress: Value(companyAddress),
      companyCity: Value(companyCity),
      companyState: Value(companyState),
      companyStateCode: Value(companyStateCode),
      companyGstin: companyGstin == null && nullToAbsent
          ? const Value.absent()
          : Value(companyGstin),
      companyPhone: companyPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(companyPhone),
      companyEmail: companyEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(companyEmail),
      companyBankName: companyBankName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyBankName),
      companyBankAccount: companyBankAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(companyBankAccount),
      companyBankIfsc: companyBankIfsc == null && nullToAbsent
          ? const Value.absent()
          : Value(companyBankIfsc),
      companyBankBranch: companyBankBranch == null && nullToAbsent
          ? const Value.absent()
          : Value(companyBankBranch),
      companyJurisdiction: companyJurisdiction == null && nullToAbsent
          ? const Value.absent()
          : Value(companyJurisdiction),
      invoiceDate: Value(invoiceDate),
      taxRegime: Value(taxRegime),
      status: Value(status),
      paymentMode: Value(paymentMode),
      subtotal: Value(subtotal),
      discountTotal: Value(discountTotal),
      taxableTotal: Value(taxableTotal),
      gstTotal: Value(gstTotal),
      grandTotal: Value(grandTotal),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdByUserId: Value(createdByUserId),
      cancelRequestId: cancelRequestId == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelRequestId),
      cancelRequestHash: cancelRequestHash == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelRequestHash),
      canceledByUserId: canceledByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(canceledByUserId),
      cancelReason: cancelReason == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelReason),
      canceledAt: canceledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(canceledAt),
      createdAt: Value(createdAt),
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Invoice(
      id: serializer.fromJson<String>(json['id']),
      requestId: serializer.fromJson<String>(json['requestId']),
      requestHash: serializer.fromJson<String>(json['requestHash']),
      invoiceNumber: serializer.fromJson<int>(json['invoiceNumber']),
      sellerId: serializer.fromJson<String>(json['sellerId']),
      sellerName: serializer.fromJson<String>(json['sellerName']),
      sellerAddress: serializer.fromJson<String>(json['sellerAddress']),
      sellerState: serializer.fromJson<String?>(json['sellerState']),
      sellerStateCode: serializer.fromJson<String?>(json['sellerStateCode']),
      sellerPhone: serializer.fromJson<String?>(json['sellerPhone']),
      sellerGstin: serializer.fromJson<String?>(json['sellerGstin']),
      placeOfSupplyState:
          serializer.fromJson<String>(json['placeOfSupplyState']),
      placeOfSupplyStateCode:
          serializer.fromJson<String>(json['placeOfSupplyStateCode']),
      companyName: serializer.fromJson<String>(json['companyName']),
      companyAddress: serializer.fromJson<String>(json['companyAddress']),
      companyCity: serializer.fromJson<String>(json['companyCity']),
      companyState: serializer.fromJson<String>(json['companyState']),
      companyStateCode: serializer.fromJson<String>(json['companyStateCode']),
      companyGstin: serializer.fromJson<String?>(json['companyGstin']),
      companyPhone: serializer.fromJson<String?>(json['companyPhone']),
      companyEmail: serializer.fromJson<String?>(json['companyEmail']),
      companyBankName: serializer.fromJson<String?>(json['companyBankName']),
      companyBankAccount:
          serializer.fromJson<String?>(json['companyBankAccount']),
      companyBankIfsc: serializer.fromJson<String?>(json['companyBankIfsc']),
      companyBankBranch:
          serializer.fromJson<String?>(json['companyBankBranch']),
      companyJurisdiction:
          serializer.fromJson<String?>(json['companyJurisdiction']),
      invoiceDate: serializer.fromJson<String>(json['invoiceDate']),
      taxRegime: serializer.fromJson<String>(json['taxRegime']),
      status: serializer.fromJson<String>(json['status']),
      paymentMode: serializer.fromJson<String>(json['paymentMode']),
      subtotal: serializer.fromJson<String>(json['subtotal']),
      discountTotal: serializer.fromJson<String>(json['discountTotal']),
      taxableTotal: serializer.fromJson<String>(json['taxableTotal']),
      gstTotal: serializer.fromJson<String>(json['gstTotal']),
      grandTotal: serializer.fromJson<String>(json['grandTotal']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
      cancelRequestId: serializer.fromJson<String?>(json['cancelRequestId']),
      cancelRequestHash:
          serializer.fromJson<String?>(json['cancelRequestHash']),
      canceledByUserId: serializer.fromJson<String?>(json['canceledByUserId']),
      cancelReason: serializer.fromJson<String?>(json['cancelReason']),
      canceledAt: serializer.fromJson<String?>(json['canceledAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'requestId': serializer.toJson<String>(requestId),
      'requestHash': serializer.toJson<String>(requestHash),
      'invoiceNumber': serializer.toJson<int>(invoiceNumber),
      'sellerId': serializer.toJson<String>(sellerId),
      'sellerName': serializer.toJson<String>(sellerName),
      'sellerAddress': serializer.toJson<String>(sellerAddress),
      'sellerState': serializer.toJson<String?>(sellerState),
      'sellerStateCode': serializer.toJson<String?>(sellerStateCode),
      'sellerPhone': serializer.toJson<String?>(sellerPhone),
      'sellerGstin': serializer.toJson<String?>(sellerGstin),
      'placeOfSupplyState': serializer.toJson<String>(placeOfSupplyState),
      'placeOfSupplyStateCode':
          serializer.toJson<String>(placeOfSupplyStateCode),
      'companyName': serializer.toJson<String>(companyName),
      'companyAddress': serializer.toJson<String>(companyAddress),
      'companyCity': serializer.toJson<String>(companyCity),
      'companyState': serializer.toJson<String>(companyState),
      'companyStateCode': serializer.toJson<String>(companyStateCode),
      'companyGstin': serializer.toJson<String?>(companyGstin),
      'companyPhone': serializer.toJson<String?>(companyPhone),
      'companyEmail': serializer.toJson<String?>(companyEmail),
      'companyBankName': serializer.toJson<String?>(companyBankName),
      'companyBankAccount': serializer.toJson<String?>(companyBankAccount),
      'companyBankIfsc': serializer.toJson<String?>(companyBankIfsc),
      'companyBankBranch': serializer.toJson<String?>(companyBankBranch),
      'companyJurisdiction': serializer.toJson<String?>(companyJurisdiction),
      'invoiceDate': serializer.toJson<String>(invoiceDate),
      'taxRegime': serializer.toJson<String>(taxRegime),
      'status': serializer.toJson<String>(status),
      'paymentMode': serializer.toJson<String>(paymentMode),
      'subtotal': serializer.toJson<String>(subtotal),
      'discountTotal': serializer.toJson<String>(discountTotal),
      'taxableTotal': serializer.toJson<String>(taxableTotal),
      'gstTotal': serializer.toJson<String>(gstTotal),
      'grandTotal': serializer.toJson<String>(grandTotal),
      'notes': serializer.toJson<String?>(notes),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
      'cancelRequestId': serializer.toJson<String?>(cancelRequestId),
      'cancelRequestHash': serializer.toJson<String?>(cancelRequestHash),
      'canceledByUserId': serializer.toJson<String?>(canceledByUserId),
      'cancelReason': serializer.toJson<String?>(cancelReason),
      'canceledAt': serializer.toJson<String?>(canceledAt),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Invoice copyWith(
          {String? id,
          String? requestId,
          String? requestHash,
          int? invoiceNumber,
          String? sellerId,
          String? sellerName,
          String? sellerAddress,
          Value<String?> sellerState = const Value.absent(),
          Value<String?> sellerStateCode = const Value.absent(),
          Value<String?> sellerPhone = const Value.absent(),
          Value<String?> sellerGstin = const Value.absent(),
          String? placeOfSupplyState,
          String? placeOfSupplyStateCode,
          String? companyName,
          String? companyAddress,
          String? companyCity,
          String? companyState,
          String? companyStateCode,
          Value<String?> companyGstin = const Value.absent(),
          Value<String?> companyPhone = const Value.absent(),
          Value<String?> companyEmail = const Value.absent(),
          Value<String?> companyBankName = const Value.absent(),
          Value<String?> companyBankAccount = const Value.absent(),
          Value<String?> companyBankIfsc = const Value.absent(),
          Value<String?> companyBankBranch = const Value.absent(),
          Value<String?> companyJurisdiction = const Value.absent(),
          String? invoiceDate,
          String? taxRegime,
          String? status,
          String? paymentMode,
          String? subtotal,
          String? discountTotal,
          String? taxableTotal,
          String? gstTotal,
          String? grandTotal,
          Value<String?> notes = const Value.absent(),
          String? createdByUserId,
          Value<String?> cancelRequestId = const Value.absent(),
          Value<String?> cancelRequestHash = const Value.absent(),
          Value<String?> canceledByUserId = const Value.absent(),
          Value<String?> cancelReason = const Value.absent(),
          Value<String?> canceledAt = const Value.absent(),
          String? createdAt}) =>
      Invoice(
        id: id ?? this.id,
        requestId: requestId ?? this.requestId,
        requestHash: requestHash ?? this.requestHash,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        sellerId: sellerId ?? this.sellerId,
        sellerName: sellerName ?? this.sellerName,
        sellerAddress: sellerAddress ?? this.sellerAddress,
        sellerState: sellerState.present ? sellerState.value : this.sellerState,
        sellerStateCode: sellerStateCode.present
            ? sellerStateCode.value
            : this.sellerStateCode,
        sellerPhone: sellerPhone.present ? sellerPhone.value : this.sellerPhone,
        sellerGstin: sellerGstin.present ? sellerGstin.value : this.sellerGstin,
        placeOfSupplyState: placeOfSupplyState ?? this.placeOfSupplyState,
        placeOfSupplyStateCode:
            placeOfSupplyStateCode ?? this.placeOfSupplyStateCode,
        companyName: companyName ?? this.companyName,
        companyAddress: companyAddress ?? this.companyAddress,
        companyCity: companyCity ?? this.companyCity,
        companyState: companyState ?? this.companyState,
        companyStateCode: companyStateCode ?? this.companyStateCode,
        companyGstin:
            companyGstin.present ? companyGstin.value : this.companyGstin,
        companyPhone:
            companyPhone.present ? companyPhone.value : this.companyPhone,
        companyEmail:
            companyEmail.present ? companyEmail.value : this.companyEmail,
        companyBankName: companyBankName.present
            ? companyBankName.value
            : this.companyBankName,
        companyBankAccount: companyBankAccount.present
            ? companyBankAccount.value
            : this.companyBankAccount,
        companyBankIfsc: companyBankIfsc.present
            ? companyBankIfsc.value
            : this.companyBankIfsc,
        companyBankBranch: companyBankBranch.present
            ? companyBankBranch.value
            : this.companyBankBranch,
        companyJurisdiction: companyJurisdiction.present
            ? companyJurisdiction.value
            : this.companyJurisdiction,
        invoiceDate: invoiceDate ?? this.invoiceDate,
        taxRegime: taxRegime ?? this.taxRegime,
        status: status ?? this.status,
        paymentMode: paymentMode ?? this.paymentMode,
        subtotal: subtotal ?? this.subtotal,
        discountTotal: discountTotal ?? this.discountTotal,
        taxableTotal: taxableTotal ?? this.taxableTotal,
        gstTotal: gstTotal ?? this.gstTotal,
        grandTotal: grandTotal ?? this.grandTotal,
        notes: notes.present ? notes.value : this.notes,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        cancelRequestId: cancelRequestId.present
            ? cancelRequestId.value
            : this.cancelRequestId,
        cancelRequestHash: cancelRequestHash.present
            ? cancelRequestHash.value
            : this.cancelRequestHash,
        canceledByUserId: canceledByUserId.present
            ? canceledByUserId.value
            : this.canceledByUserId,
        cancelReason:
            cancelReason.present ? cancelReason.value : this.cancelReason,
        canceledAt: canceledAt.present ? canceledAt.value : this.canceledAt,
        createdAt: createdAt ?? this.createdAt,
      );
  Invoice copyWithCompanion(InvoicesCompanion data) {
    return Invoice(
      id: data.id.present ? data.id.value : this.id,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      requestHash:
          data.requestHash.present ? data.requestHash.value : this.requestHash,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      sellerId: data.sellerId.present ? data.sellerId.value : this.sellerId,
      sellerName:
          data.sellerName.present ? data.sellerName.value : this.sellerName,
      sellerAddress: data.sellerAddress.present
          ? data.sellerAddress.value
          : this.sellerAddress,
      sellerState:
          data.sellerState.present ? data.sellerState.value : this.sellerState,
      sellerStateCode: data.sellerStateCode.present
          ? data.sellerStateCode.value
          : this.sellerStateCode,
      sellerPhone:
          data.sellerPhone.present ? data.sellerPhone.value : this.sellerPhone,
      sellerGstin:
          data.sellerGstin.present ? data.sellerGstin.value : this.sellerGstin,
      placeOfSupplyState: data.placeOfSupplyState.present
          ? data.placeOfSupplyState.value
          : this.placeOfSupplyState,
      placeOfSupplyStateCode: data.placeOfSupplyStateCode.present
          ? data.placeOfSupplyStateCode.value
          : this.placeOfSupplyStateCode,
      companyName:
          data.companyName.present ? data.companyName.value : this.companyName,
      companyAddress: data.companyAddress.present
          ? data.companyAddress.value
          : this.companyAddress,
      companyCity:
          data.companyCity.present ? data.companyCity.value : this.companyCity,
      companyState: data.companyState.present
          ? data.companyState.value
          : this.companyState,
      companyStateCode: data.companyStateCode.present
          ? data.companyStateCode.value
          : this.companyStateCode,
      companyGstin: data.companyGstin.present
          ? data.companyGstin.value
          : this.companyGstin,
      companyPhone: data.companyPhone.present
          ? data.companyPhone.value
          : this.companyPhone,
      companyEmail: data.companyEmail.present
          ? data.companyEmail.value
          : this.companyEmail,
      companyBankName: data.companyBankName.present
          ? data.companyBankName.value
          : this.companyBankName,
      companyBankAccount: data.companyBankAccount.present
          ? data.companyBankAccount.value
          : this.companyBankAccount,
      companyBankIfsc: data.companyBankIfsc.present
          ? data.companyBankIfsc.value
          : this.companyBankIfsc,
      companyBankBranch: data.companyBankBranch.present
          ? data.companyBankBranch.value
          : this.companyBankBranch,
      companyJurisdiction: data.companyJurisdiction.present
          ? data.companyJurisdiction.value
          : this.companyJurisdiction,
      invoiceDate:
          data.invoiceDate.present ? data.invoiceDate.value : this.invoiceDate,
      taxRegime: data.taxRegime.present ? data.taxRegime.value : this.taxRegime,
      status: data.status.present ? data.status.value : this.status,
      paymentMode:
          data.paymentMode.present ? data.paymentMode.value : this.paymentMode,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discountTotal: data.discountTotal.present
          ? data.discountTotal.value
          : this.discountTotal,
      taxableTotal: data.taxableTotal.present
          ? data.taxableTotal.value
          : this.taxableTotal,
      gstTotal: data.gstTotal.present ? data.gstTotal.value : this.gstTotal,
      grandTotal:
          data.grandTotal.present ? data.grandTotal.value : this.grandTotal,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      cancelRequestId: data.cancelRequestId.present
          ? data.cancelRequestId.value
          : this.cancelRequestId,
      cancelRequestHash: data.cancelRequestHash.present
          ? data.cancelRequestHash.value
          : this.cancelRequestHash,
      canceledByUserId: data.canceledByUserId.present
          ? data.canceledByUserId.value
          : this.canceledByUserId,
      cancelReason: data.cancelReason.present
          ? data.cancelReason.value
          : this.cancelReason,
      canceledAt:
          data.canceledAt.present ? data.canceledAt.value : this.canceledAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Invoice(')
          ..write('id: $id, ')
          ..write('requestId: $requestId, ')
          ..write('requestHash: $requestHash, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('sellerId: $sellerId, ')
          ..write('sellerName: $sellerName, ')
          ..write('sellerAddress: $sellerAddress, ')
          ..write('sellerState: $sellerState, ')
          ..write('sellerStateCode: $sellerStateCode, ')
          ..write('sellerPhone: $sellerPhone, ')
          ..write('sellerGstin: $sellerGstin, ')
          ..write('placeOfSupplyState: $placeOfSupplyState, ')
          ..write('placeOfSupplyStateCode: $placeOfSupplyStateCode, ')
          ..write('companyName: $companyName, ')
          ..write('companyAddress: $companyAddress, ')
          ..write('companyCity: $companyCity, ')
          ..write('companyState: $companyState, ')
          ..write('companyStateCode: $companyStateCode, ')
          ..write('companyGstin: $companyGstin, ')
          ..write('companyPhone: $companyPhone, ')
          ..write('companyEmail: $companyEmail, ')
          ..write('companyBankName: $companyBankName, ')
          ..write('companyBankAccount: $companyBankAccount, ')
          ..write('companyBankIfsc: $companyBankIfsc, ')
          ..write('companyBankBranch: $companyBankBranch, ')
          ..write('companyJurisdiction: $companyJurisdiction, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('taxRegime: $taxRegime, ')
          ..write('status: $status, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('taxableTotal: $taxableTotal, ')
          ..write('gstTotal: $gstTotal, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('cancelRequestId: $cancelRequestId, ')
          ..write('cancelRequestHash: $cancelRequestHash, ')
          ..write('canceledByUserId: $canceledByUserId, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('canceledAt: $canceledAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        requestId,
        requestHash,
        invoiceNumber,
        sellerId,
        sellerName,
        sellerAddress,
        sellerState,
        sellerStateCode,
        sellerPhone,
        sellerGstin,
        placeOfSupplyState,
        placeOfSupplyStateCode,
        companyName,
        companyAddress,
        companyCity,
        companyState,
        companyStateCode,
        companyGstin,
        companyPhone,
        companyEmail,
        companyBankName,
        companyBankAccount,
        companyBankIfsc,
        companyBankBranch,
        companyJurisdiction,
        invoiceDate,
        taxRegime,
        status,
        paymentMode,
        subtotal,
        discountTotal,
        taxableTotal,
        gstTotal,
        grandTotal,
        notes,
        createdByUserId,
        cancelRequestId,
        cancelRequestHash,
        canceledByUserId,
        cancelReason,
        canceledAt,
        createdAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Invoice &&
          other.id == this.id &&
          other.requestId == this.requestId &&
          other.requestHash == this.requestHash &&
          other.invoiceNumber == this.invoiceNumber &&
          other.sellerId == this.sellerId &&
          other.sellerName == this.sellerName &&
          other.sellerAddress == this.sellerAddress &&
          other.sellerState == this.sellerState &&
          other.sellerStateCode == this.sellerStateCode &&
          other.sellerPhone == this.sellerPhone &&
          other.sellerGstin == this.sellerGstin &&
          other.placeOfSupplyState == this.placeOfSupplyState &&
          other.placeOfSupplyStateCode == this.placeOfSupplyStateCode &&
          other.companyName == this.companyName &&
          other.companyAddress == this.companyAddress &&
          other.companyCity == this.companyCity &&
          other.companyState == this.companyState &&
          other.companyStateCode == this.companyStateCode &&
          other.companyGstin == this.companyGstin &&
          other.companyPhone == this.companyPhone &&
          other.companyEmail == this.companyEmail &&
          other.companyBankName == this.companyBankName &&
          other.companyBankAccount == this.companyBankAccount &&
          other.companyBankIfsc == this.companyBankIfsc &&
          other.companyBankBranch == this.companyBankBranch &&
          other.companyJurisdiction == this.companyJurisdiction &&
          other.invoiceDate == this.invoiceDate &&
          other.taxRegime == this.taxRegime &&
          other.status == this.status &&
          other.paymentMode == this.paymentMode &&
          other.subtotal == this.subtotal &&
          other.discountTotal == this.discountTotal &&
          other.taxableTotal == this.taxableTotal &&
          other.gstTotal == this.gstTotal &&
          other.grandTotal == this.grandTotal &&
          other.notes == this.notes &&
          other.createdByUserId == this.createdByUserId &&
          other.cancelRequestId == this.cancelRequestId &&
          other.cancelRequestHash == this.cancelRequestHash &&
          other.canceledByUserId == this.canceledByUserId &&
          other.cancelReason == this.cancelReason &&
          other.canceledAt == this.canceledAt &&
          other.createdAt == this.createdAt);
}

class InvoicesCompanion extends UpdateCompanion<Invoice> {
  final Value<String> id;
  final Value<String> requestId;
  final Value<String> requestHash;
  final Value<int> invoiceNumber;
  final Value<String> sellerId;
  final Value<String> sellerName;
  final Value<String> sellerAddress;
  final Value<String?> sellerState;
  final Value<String?> sellerStateCode;
  final Value<String?> sellerPhone;
  final Value<String?> sellerGstin;
  final Value<String> placeOfSupplyState;
  final Value<String> placeOfSupplyStateCode;
  final Value<String> companyName;
  final Value<String> companyAddress;
  final Value<String> companyCity;
  final Value<String> companyState;
  final Value<String> companyStateCode;
  final Value<String?> companyGstin;
  final Value<String?> companyPhone;
  final Value<String?> companyEmail;
  final Value<String?> companyBankName;
  final Value<String?> companyBankAccount;
  final Value<String?> companyBankIfsc;
  final Value<String?> companyBankBranch;
  final Value<String?> companyJurisdiction;
  final Value<String> invoiceDate;
  final Value<String> taxRegime;
  final Value<String> status;
  final Value<String> paymentMode;
  final Value<String> subtotal;
  final Value<String> discountTotal;
  final Value<String> taxableTotal;
  final Value<String> gstTotal;
  final Value<String> grandTotal;
  final Value<String?> notes;
  final Value<String> createdByUserId;
  final Value<String?> cancelRequestId;
  final Value<String?> cancelRequestHash;
  final Value<String?> canceledByUserId;
  final Value<String?> cancelReason;
  final Value<String?> canceledAt;
  final Value<String> createdAt;
  final Value<int> rowid;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.requestId = const Value.absent(),
    this.requestHash = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.sellerId = const Value.absent(),
    this.sellerName = const Value.absent(),
    this.sellerAddress = const Value.absent(),
    this.sellerState = const Value.absent(),
    this.sellerStateCode = const Value.absent(),
    this.sellerPhone = const Value.absent(),
    this.sellerGstin = const Value.absent(),
    this.placeOfSupplyState = const Value.absent(),
    this.placeOfSupplyStateCode = const Value.absent(),
    this.companyName = const Value.absent(),
    this.companyAddress = const Value.absent(),
    this.companyCity = const Value.absent(),
    this.companyState = const Value.absent(),
    this.companyStateCode = const Value.absent(),
    this.companyGstin = const Value.absent(),
    this.companyPhone = const Value.absent(),
    this.companyEmail = const Value.absent(),
    this.companyBankName = const Value.absent(),
    this.companyBankAccount = const Value.absent(),
    this.companyBankIfsc = const Value.absent(),
    this.companyBankBranch = const Value.absent(),
    this.companyJurisdiction = const Value.absent(),
    this.invoiceDate = const Value.absent(),
    this.taxRegime = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentMode = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountTotal = const Value.absent(),
    this.taxableTotal = const Value.absent(),
    this.gstTotal = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.cancelRequestId = const Value.absent(),
    this.cancelRequestHash = const Value.absent(),
    this.canceledByUserId = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.canceledAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoicesCompanion.insert({
    required String id,
    required String requestId,
    required String requestHash,
    required int invoiceNumber,
    required String sellerId,
    required String sellerName,
    required String sellerAddress,
    this.sellerState = const Value.absent(),
    this.sellerStateCode = const Value.absent(),
    this.sellerPhone = const Value.absent(),
    this.sellerGstin = const Value.absent(),
    required String placeOfSupplyState,
    required String placeOfSupplyStateCode,
    required String companyName,
    required String companyAddress,
    required String companyCity,
    required String companyState,
    required String companyStateCode,
    this.companyGstin = const Value.absent(),
    this.companyPhone = const Value.absent(),
    this.companyEmail = const Value.absent(),
    this.companyBankName = const Value.absent(),
    this.companyBankAccount = const Value.absent(),
    this.companyBankIfsc = const Value.absent(),
    this.companyBankBranch = const Value.absent(),
    this.companyJurisdiction = const Value.absent(),
    required String invoiceDate,
    required String taxRegime,
    required String status,
    required String paymentMode,
    required String subtotal,
    required String discountTotal,
    required String taxableTotal,
    required String gstTotal,
    required String grandTotal,
    this.notes = const Value.absent(),
    required String createdByUserId,
    this.cancelRequestId = const Value.absent(),
    this.cancelRequestHash = const Value.absent(),
    this.canceledByUserId = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.canceledAt = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        requestId = Value(requestId),
        requestHash = Value(requestHash),
        invoiceNumber = Value(invoiceNumber),
        sellerId = Value(sellerId),
        sellerName = Value(sellerName),
        sellerAddress = Value(sellerAddress),
        placeOfSupplyState = Value(placeOfSupplyState),
        placeOfSupplyStateCode = Value(placeOfSupplyStateCode),
        companyName = Value(companyName),
        companyAddress = Value(companyAddress),
        companyCity = Value(companyCity),
        companyState = Value(companyState),
        companyStateCode = Value(companyStateCode),
        invoiceDate = Value(invoiceDate),
        taxRegime = Value(taxRegime),
        status = Value(status),
        paymentMode = Value(paymentMode),
        subtotal = Value(subtotal),
        discountTotal = Value(discountTotal),
        taxableTotal = Value(taxableTotal),
        gstTotal = Value(gstTotal),
        grandTotal = Value(grandTotal),
        createdByUserId = Value(createdByUserId),
        createdAt = Value(createdAt);
  static Insertable<Invoice> custom({
    Expression<String>? id,
    Expression<String>? requestId,
    Expression<String>? requestHash,
    Expression<int>? invoiceNumber,
    Expression<String>? sellerId,
    Expression<String>? sellerName,
    Expression<String>? sellerAddress,
    Expression<String>? sellerState,
    Expression<String>? sellerStateCode,
    Expression<String>? sellerPhone,
    Expression<String>? sellerGstin,
    Expression<String>? placeOfSupplyState,
    Expression<String>? placeOfSupplyStateCode,
    Expression<String>? companyName,
    Expression<String>? companyAddress,
    Expression<String>? companyCity,
    Expression<String>? companyState,
    Expression<String>? companyStateCode,
    Expression<String>? companyGstin,
    Expression<String>? companyPhone,
    Expression<String>? companyEmail,
    Expression<String>? companyBankName,
    Expression<String>? companyBankAccount,
    Expression<String>? companyBankIfsc,
    Expression<String>? companyBankBranch,
    Expression<String>? companyJurisdiction,
    Expression<String>? invoiceDate,
    Expression<String>? taxRegime,
    Expression<String>? status,
    Expression<String>? paymentMode,
    Expression<String>? subtotal,
    Expression<String>? discountTotal,
    Expression<String>? taxableTotal,
    Expression<String>? gstTotal,
    Expression<String>? grandTotal,
    Expression<String>? notes,
    Expression<String>? createdByUserId,
    Expression<String>? cancelRequestId,
    Expression<String>? cancelRequestHash,
    Expression<String>? canceledByUserId,
    Expression<String>? cancelReason,
    Expression<String>? canceledAt,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (requestId != null) 'request_id': requestId,
      if (requestHash != null) 'request_hash': requestHash,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (sellerId != null) 'seller_id': sellerId,
      if (sellerName != null) 'seller_name': sellerName,
      if (sellerAddress != null) 'seller_address': sellerAddress,
      if (sellerState != null) 'seller_state': sellerState,
      if (sellerStateCode != null) 'seller_state_code': sellerStateCode,
      if (sellerPhone != null) 'seller_phone': sellerPhone,
      if (sellerGstin != null) 'seller_gstin': sellerGstin,
      if (placeOfSupplyState != null)
        'place_of_supply_state': placeOfSupplyState,
      if (placeOfSupplyStateCode != null)
        'place_of_supply_state_code': placeOfSupplyStateCode,
      if (companyName != null) 'company_name': companyName,
      if (companyAddress != null) 'company_address': companyAddress,
      if (companyCity != null) 'company_city': companyCity,
      if (companyState != null) 'company_state': companyState,
      if (companyStateCode != null) 'company_state_code': companyStateCode,
      if (companyGstin != null) 'company_gstin': companyGstin,
      if (companyPhone != null) 'company_phone': companyPhone,
      if (companyEmail != null) 'company_email': companyEmail,
      if (companyBankName != null) 'company_bank_name': companyBankName,
      if (companyBankAccount != null)
        'company_bank_account': companyBankAccount,
      if (companyBankIfsc != null) 'company_bank_ifsc': companyBankIfsc,
      if (companyBankBranch != null) 'company_bank_branch': companyBankBranch,
      if (companyJurisdiction != null)
        'company_jurisdiction': companyJurisdiction,
      if (invoiceDate != null) 'invoice_date': invoiceDate,
      if (taxRegime != null) 'tax_regime': taxRegime,
      if (status != null) 'status': status,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (subtotal != null) 'subtotal': subtotal,
      if (discountTotal != null) 'discount_total': discountTotal,
      if (taxableTotal != null) 'taxable_total': taxableTotal,
      if (gstTotal != null) 'gst_total': gstTotal,
      if (grandTotal != null) 'grand_total': grandTotal,
      if (notes != null) 'notes': notes,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (cancelRequestId != null) 'cancel_request_id': cancelRequestId,
      if (cancelRequestHash != null) 'cancel_request_hash': cancelRequestHash,
      if (canceledByUserId != null) 'canceled_by_user_id': canceledByUserId,
      if (cancelReason != null) 'cancel_reason': cancelReason,
      if (canceledAt != null) 'canceled_at': canceledAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoicesCompanion copyWith(
      {Value<String>? id,
      Value<String>? requestId,
      Value<String>? requestHash,
      Value<int>? invoiceNumber,
      Value<String>? sellerId,
      Value<String>? sellerName,
      Value<String>? sellerAddress,
      Value<String?>? sellerState,
      Value<String?>? sellerStateCode,
      Value<String?>? sellerPhone,
      Value<String?>? sellerGstin,
      Value<String>? placeOfSupplyState,
      Value<String>? placeOfSupplyStateCode,
      Value<String>? companyName,
      Value<String>? companyAddress,
      Value<String>? companyCity,
      Value<String>? companyState,
      Value<String>? companyStateCode,
      Value<String?>? companyGstin,
      Value<String?>? companyPhone,
      Value<String?>? companyEmail,
      Value<String?>? companyBankName,
      Value<String?>? companyBankAccount,
      Value<String?>? companyBankIfsc,
      Value<String?>? companyBankBranch,
      Value<String?>? companyJurisdiction,
      Value<String>? invoiceDate,
      Value<String>? taxRegime,
      Value<String>? status,
      Value<String>? paymentMode,
      Value<String>? subtotal,
      Value<String>? discountTotal,
      Value<String>? taxableTotal,
      Value<String>? gstTotal,
      Value<String>? grandTotal,
      Value<String?>? notes,
      Value<String>? createdByUserId,
      Value<String?>? cancelRequestId,
      Value<String?>? cancelRequestHash,
      Value<String?>? canceledByUserId,
      Value<String?>? cancelReason,
      Value<String?>? canceledAt,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return InvoicesCompanion(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerState: sellerState ?? this.sellerState,
      sellerStateCode: sellerStateCode ?? this.sellerStateCode,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerGstin: sellerGstin ?? this.sellerGstin,
      placeOfSupplyState: placeOfSupplyState ?? this.placeOfSupplyState,
      placeOfSupplyStateCode:
          placeOfSupplyStateCode ?? this.placeOfSupplyStateCode,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyCity: companyCity ?? this.companyCity,
      companyState: companyState ?? this.companyState,
      companyStateCode: companyStateCode ?? this.companyStateCode,
      companyGstin: companyGstin ?? this.companyGstin,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      companyBankName: companyBankName ?? this.companyBankName,
      companyBankAccount: companyBankAccount ?? this.companyBankAccount,
      companyBankIfsc: companyBankIfsc ?? this.companyBankIfsc,
      companyBankBranch: companyBankBranch ?? this.companyBankBranch,
      companyJurisdiction: companyJurisdiction ?? this.companyJurisdiction,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      taxRegime: taxRegime ?? this.taxRegime,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      subtotal: subtotal ?? this.subtotal,
      discountTotal: discountTotal ?? this.discountTotal,
      taxableTotal: taxableTotal ?? this.taxableTotal,
      gstTotal: gstTotal ?? this.gstTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      notes: notes ?? this.notes,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      cancelRequestId: cancelRequestId ?? this.cancelRequestId,
      cancelRequestHash: cancelRequestHash ?? this.cancelRequestHash,
      canceledByUserId: canceledByUserId ?? this.canceledByUserId,
      cancelReason: cancelReason ?? this.cancelReason,
      canceledAt: canceledAt ?? this.canceledAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (requestHash.present) {
      map['request_hash'] = Variable<String>(requestHash.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<int>(invoiceNumber.value);
    }
    if (sellerId.present) {
      map['seller_id'] = Variable<String>(sellerId.value);
    }
    if (sellerName.present) {
      map['seller_name'] = Variable<String>(sellerName.value);
    }
    if (sellerAddress.present) {
      map['seller_address'] = Variable<String>(sellerAddress.value);
    }
    if (sellerState.present) {
      map['seller_state'] = Variable<String>(sellerState.value);
    }
    if (sellerStateCode.present) {
      map['seller_state_code'] = Variable<String>(sellerStateCode.value);
    }
    if (sellerPhone.present) {
      map['seller_phone'] = Variable<String>(sellerPhone.value);
    }
    if (sellerGstin.present) {
      map['seller_gstin'] = Variable<String>(sellerGstin.value);
    }
    if (placeOfSupplyState.present) {
      map['place_of_supply_state'] = Variable<String>(placeOfSupplyState.value);
    }
    if (placeOfSupplyStateCode.present) {
      map['place_of_supply_state_code'] =
          Variable<String>(placeOfSupplyStateCode.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (companyAddress.present) {
      map['company_address'] = Variable<String>(companyAddress.value);
    }
    if (companyCity.present) {
      map['company_city'] = Variable<String>(companyCity.value);
    }
    if (companyState.present) {
      map['company_state'] = Variable<String>(companyState.value);
    }
    if (companyStateCode.present) {
      map['company_state_code'] = Variable<String>(companyStateCode.value);
    }
    if (companyGstin.present) {
      map['company_gstin'] = Variable<String>(companyGstin.value);
    }
    if (companyPhone.present) {
      map['company_phone'] = Variable<String>(companyPhone.value);
    }
    if (companyEmail.present) {
      map['company_email'] = Variable<String>(companyEmail.value);
    }
    if (companyBankName.present) {
      map['company_bank_name'] = Variable<String>(companyBankName.value);
    }
    if (companyBankAccount.present) {
      map['company_bank_account'] = Variable<String>(companyBankAccount.value);
    }
    if (companyBankIfsc.present) {
      map['company_bank_ifsc'] = Variable<String>(companyBankIfsc.value);
    }
    if (companyBankBranch.present) {
      map['company_bank_branch'] = Variable<String>(companyBankBranch.value);
    }
    if (companyJurisdiction.present) {
      map['company_jurisdiction'] = Variable<String>(companyJurisdiction.value);
    }
    if (invoiceDate.present) {
      map['invoice_date'] = Variable<String>(invoiceDate.value);
    }
    if (taxRegime.present) {
      map['tax_regime'] = Variable<String>(taxRegime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paymentMode.present) {
      map['payment_mode'] = Variable<String>(paymentMode.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<String>(subtotal.value);
    }
    if (discountTotal.present) {
      map['discount_total'] = Variable<String>(discountTotal.value);
    }
    if (taxableTotal.present) {
      map['taxable_total'] = Variable<String>(taxableTotal.value);
    }
    if (gstTotal.present) {
      map['gst_total'] = Variable<String>(gstTotal.value);
    }
    if (grandTotal.present) {
      map['grand_total'] = Variable<String>(grandTotal.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (cancelRequestId.present) {
      map['cancel_request_id'] = Variable<String>(cancelRequestId.value);
    }
    if (cancelRequestHash.present) {
      map['cancel_request_hash'] = Variable<String>(cancelRequestHash.value);
    }
    if (canceledByUserId.present) {
      map['canceled_by_user_id'] = Variable<String>(canceledByUserId.value);
    }
    if (cancelReason.present) {
      map['cancel_reason'] = Variable<String>(cancelReason.value);
    }
    if (canceledAt.present) {
      map['canceled_at'] = Variable<String>(canceledAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('requestId: $requestId, ')
          ..write('requestHash: $requestHash, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('sellerId: $sellerId, ')
          ..write('sellerName: $sellerName, ')
          ..write('sellerAddress: $sellerAddress, ')
          ..write('sellerState: $sellerState, ')
          ..write('sellerStateCode: $sellerStateCode, ')
          ..write('sellerPhone: $sellerPhone, ')
          ..write('sellerGstin: $sellerGstin, ')
          ..write('placeOfSupplyState: $placeOfSupplyState, ')
          ..write('placeOfSupplyStateCode: $placeOfSupplyStateCode, ')
          ..write('companyName: $companyName, ')
          ..write('companyAddress: $companyAddress, ')
          ..write('companyCity: $companyCity, ')
          ..write('companyState: $companyState, ')
          ..write('companyStateCode: $companyStateCode, ')
          ..write('companyGstin: $companyGstin, ')
          ..write('companyPhone: $companyPhone, ')
          ..write('companyEmail: $companyEmail, ')
          ..write('companyBankName: $companyBankName, ')
          ..write('companyBankAccount: $companyBankAccount, ')
          ..write('companyBankIfsc: $companyBankIfsc, ')
          ..write('companyBankBranch: $companyBankBranch, ')
          ..write('companyJurisdiction: $companyJurisdiction, ')
          ..write('invoiceDate: $invoiceDate, ')
          ..write('taxRegime: $taxRegime, ')
          ..write('status: $status, ')
          ..write('paymentMode: $paymentMode, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('taxableTotal: $taxableTotal, ')
          ..write('gstTotal: $gstTotal, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('cancelRequestId: $cancelRequestId, ')
          ..write('cancelRequestHash: $cancelRequestHash, ')
          ..write('canceledByUserId: $canceledByUserId, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('canceledAt: $canceledAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTable extends StockMovements
    with TableInfo<$StockMovementsTable, StockMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _invoiceIdMeta =
      const VerificationMeta('invoiceId');
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
      'invoice_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES invoices (id)'));
  static const VerificationMeta _requestIdMeta =
      const VerificationMeta('requestId');
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
      'request_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _requestHashMeta =
      const VerificationMeta('requestHash');
  @override
  late final GeneratedColumn<String> requestHash = GeneratedColumn<String>(
      'request_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _movementTypeMeta =
      const VerificationMeta('movementType');
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
      'movement_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityDeltaMeta =
      const VerificationMeta('quantityDelta');
  @override
  late final GeneratedColumn<String> quantityDelta = GeneratedColumn<String>(
      'quantity_delta', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
      'created_by_user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES local_users (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        productId,
        invoiceId,
        requestId,
        requestHash,
        movementType,
        quantityDelta,
        reason,
        createdByUserId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(Insertable<StockMovement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(_invoiceIdMeta,
          invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta));
    }
    if (data.containsKey('request_id')) {
      context.handle(_requestIdMeta,
          requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta));
    }
    if (data.containsKey('request_hash')) {
      context.handle(
          _requestHashMeta,
          requestHash.isAcceptableOrUnknown(
              data['request_hash']!, _requestHashMeta));
    }
    if (data.containsKey('movement_type')) {
      context.handle(
          _movementTypeMeta,
          movementType.isAcceptableOrUnknown(
              data['movement_type']!, _movementTypeMeta));
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('quantity_delta')) {
      context.handle(
          _quantityDeltaMeta,
          quantityDelta.isAcceptableOrUnknown(
              data['quantity_delta']!, _quantityDeltaMeta));
    } else if (isInserting) {
      context.missing(_quantityDeltaMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      invoiceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_id']),
      requestId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_id']),
      requestHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_hash']),
      movementType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}movement_type'])!,
      quantityDelta: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quantity_delta'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
      createdByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}created_by_user_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StockMovementsTable createAlias(String alias) {
    return $StockMovementsTable(attachedDatabase, alias);
  }
}

class StockMovement extends DataClass implements Insertable<StockMovement> {
  final String id;
  final String productId;
  final String? invoiceId;
  final String? requestId;
  final String? requestHash;
  final String movementType;
  final String quantityDelta;
  final String? reason;
  final String createdByUserId;
  final String createdAt;
  const StockMovement(
      {required this.id,
      required this.productId,
      this.invoiceId,
      this.requestId,
      this.requestHash,
      required this.movementType,
      required this.quantityDelta,
      this.reason,
      required this.createdByUserId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || invoiceId != null) {
      map['invoice_id'] = Variable<String>(invoiceId);
    }
    if (!nullToAbsent || requestId != null) {
      map['request_id'] = Variable<String>(requestId);
    }
    if (!nullToAbsent || requestHash != null) {
      map['request_hash'] = Variable<String>(requestHash);
    }
    map['movement_type'] = Variable<String>(movementType);
    map['quantity_delta'] = Variable<String>(quantityDelta);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  StockMovementsCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsCompanion(
      id: Value(id),
      productId: Value(productId),
      invoiceId: invoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceId),
      requestId: requestId == null && nullToAbsent
          ? const Value.absent()
          : Value(requestId),
      requestHash: requestHash == null && nullToAbsent
          ? const Value.absent()
          : Value(requestHash),
      movementType: Value(movementType),
      quantityDelta: Value(quantityDelta),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      createdByUserId: Value(createdByUserId),
      createdAt: Value(createdAt),
    );
  }

  factory StockMovement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovement(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      invoiceId: serializer.fromJson<String?>(json['invoiceId']),
      requestId: serializer.fromJson<String?>(json['requestId']),
      requestHash: serializer.fromJson<String?>(json['requestHash']),
      movementType: serializer.fromJson<String>(json['movementType']),
      quantityDelta: serializer.fromJson<String>(json['quantityDelta']),
      reason: serializer.fromJson<String?>(json['reason']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'invoiceId': serializer.toJson<String?>(invoiceId),
      'requestId': serializer.toJson<String?>(requestId),
      'requestHash': serializer.toJson<String?>(requestHash),
      'movementType': serializer.toJson<String>(movementType),
      'quantityDelta': serializer.toJson<String>(quantityDelta),
      'reason': serializer.toJson<String?>(reason),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  StockMovement copyWith(
          {String? id,
          String? productId,
          Value<String?> invoiceId = const Value.absent(),
          Value<String?> requestId = const Value.absent(),
          Value<String?> requestHash = const Value.absent(),
          String? movementType,
          String? quantityDelta,
          Value<String?> reason = const Value.absent(),
          String? createdByUserId,
          String? createdAt}) =>
      StockMovement(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        invoiceId: invoiceId.present ? invoiceId.value : this.invoiceId,
        requestId: requestId.present ? requestId.value : this.requestId,
        requestHash: requestHash.present ? requestHash.value : this.requestHash,
        movementType: movementType ?? this.movementType,
        quantityDelta: quantityDelta ?? this.quantityDelta,
        reason: reason.present ? reason.value : this.reason,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        createdAt: createdAt ?? this.createdAt,
      );
  StockMovement copyWithCompanion(StockMovementsCompanion data) {
    return StockMovement(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      requestHash:
          data.requestHash.present ? data.requestHash.value : this.requestHash,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      quantityDelta: data.quantityDelta.present
          ? data.quantityDelta.value
          : this.quantityDelta,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovement(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('requestId: $requestId, ')
          ..write('requestHash: $requestHash, ')
          ..write('movementType: $movementType, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('reason: $reason, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      productId,
      invoiceId,
      requestId,
      requestHash,
      movementType,
      quantityDelta,
      reason,
      createdByUserId,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovement &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.invoiceId == this.invoiceId &&
          other.requestId == this.requestId &&
          other.requestHash == this.requestHash &&
          other.movementType == this.movementType &&
          other.quantityDelta == this.quantityDelta &&
          other.reason == this.reason &&
          other.createdByUserId == this.createdByUserId &&
          other.createdAt == this.createdAt);
}

class StockMovementsCompanion extends UpdateCompanion<StockMovement> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String?> invoiceId;
  final Value<String?> requestId;
  final Value<String?> requestHash;
  final Value<String> movementType;
  final Value<String> quantityDelta;
  final Value<String?> reason;
  final Value<String> createdByUserId;
  final Value<String> createdAt;
  final Value<int> rowid;
  const StockMovementsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.requestId = const Value.absent(),
    this.requestHash = const Value.absent(),
    this.movementType = const Value.absent(),
    this.quantityDelta = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockMovementsCompanion.insert({
    required String id,
    required String productId,
    this.invoiceId = const Value.absent(),
    this.requestId = const Value.absent(),
    this.requestHash = const Value.absent(),
    required String movementType,
    required String quantityDelta,
    this.reason = const Value.absent(),
    required String createdByUserId,
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        productId = Value(productId),
        movementType = Value(movementType),
        quantityDelta = Value(quantityDelta),
        createdByUserId = Value(createdByUserId),
        createdAt = Value(createdAt);
  static Insertable<StockMovement> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? invoiceId,
    Expression<String>? requestId,
    Expression<String>? requestHash,
    Expression<String>? movementType,
    Expression<String>? quantityDelta,
    Expression<String>? reason,
    Expression<String>? createdByUserId,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (requestId != null) 'request_id': requestId,
      if (requestHash != null) 'request_hash': requestHash,
      if (movementType != null) 'movement_type': movementType,
      if (quantityDelta != null) 'quantity_delta': quantityDelta,
      if (reason != null) 'reason': reason,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockMovementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? productId,
      Value<String?>? invoiceId,
      Value<String?>? requestId,
      Value<String?>? requestHash,
      Value<String>? movementType,
      Value<String>? quantityDelta,
      Value<String?>? reason,
      Value<String>? createdByUserId,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return StockMovementsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      invoiceId: invoiceId ?? this.invoiceId,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      movementType: movementType ?? this.movementType,
      quantityDelta: quantityDelta ?? this.quantityDelta,
      reason: reason ?? this.reason,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (requestHash.present) {
      map['request_hash'] = Variable<String>(requestHash.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (quantityDelta.present) {
      map['quantity_delta'] = Variable<String>(quantityDelta.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('requestId: $requestId, ')
          ..write('requestHash: $requestHash, ')
          ..write('movementType: $movementType, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('reason: $reason, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SellerTransactionsTable extends SellerTransactions
    with TableInfo<$SellerTransactionsTable, SellerTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SellerTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sellerIdMeta =
      const VerificationMeta('sellerId');
  @override
  late final GeneratedColumn<String> sellerId = GeneratedColumn<String>(
      'seller_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sellers (id)'));
  static const VerificationMeta _invoiceIdMeta =
      const VerificationMeta('invoiceId');
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
      'invoice_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES invoices (id)'));
  static const VerificationMeta _requestIdMeta =
      const VerificationMeta('requestId');
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
      'request_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _requestHashMeta =
      const VerificationMeta('requestHash');
  @override
  late final GeneratedColumn<String> requestHash = GeneratedColumn<String>(
      'request_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _openingBalanceSellerIdMeta =
      const VerificationMeta('openingBalanceSellerId');
  @override
  late final GeneratedColumn<String> openingBalanceSellerId =
      GeneratedColumn<String>('opening_balance_seller_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entryTypeMeta =
      const VerificationMeta('entryType');
  @override
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
      'entry_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
      'amount', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _occurredOnMeta =
      const VerificationMeta('occurredOn');
  @override
  late final GeneratedColumn<String> occurredOn = GeneratedColumn<String>(
      'occurred_on', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
      'created_by_user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES local_users (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sellerId,
        invoiceId,
        requestId,
        requestHash,
        openingBalanceSellerId,
        entryType,
        amount,
        occurredOn,
        notes,
        createdByUserId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seller_transactions';
  @override
  VerificationContext validateIntegrity(Insertable<SellerTransaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('seller_id')) {
      context.handle(_sellerIdMeta,
          sellerId.isAcceptableOrUnknown(data['seller_id']!, _sellerIdMeta));
    } else if (isInserting) {
      context.missing(_sellerIdMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(_invoiceIdMeta,
          invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta));
    }
    if (data.containsKey('request_id')) {
      context.handle(_requestIdMeta,
          requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta));
    }
    if (data.containsKey('request_hash')) {
      context.handle(
          _requestHashMeta,
          requestHash.isAcceptableOrUnknown(
              data['request_hash']!, _requestHashMeta));
    }
    if (data.containsKey('opening_balance_seller_id')) {
      context.handle(
          _openingBalanceSellerIdMeta,
          openingBalanceSellerId.isAcceptableOrUnknown(
              data['opening_balance_seller_id']!, _openingBalanceSellerIdMeta));
    }
    if (data.containsKey('entry_type')) {
      context.handle(_entryTypeMeta,
          entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta));
    } else if (isInserting) {
      context.missing(_entryTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('occurred_on')) {
      context.handle(
          _occurredOnMeta,
          occurredOn.isAcceptableOrUnknown(
              data['occurred_on']!, _occurredOnMeta));
    } else if (isInserting) {
      context.missing(_occurredOnMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {requestId},
        {openingBalanceSellerId},
      ];
  @override
  SellerTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SellerTransaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sellerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seller_id'])!,
      invoiceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_id']),
      requestId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_id']),
      requestHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_hash']),
      openingBalanceSellerId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}opening_balance_seller_id']),
      entryType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}amount'])!,
      occurredOn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}occurred_on'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}created_by_user_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SellerTransactionsTable createAlias(String alias) {
    return $SellerTransactionsTable(attachedDatabase, alias);
  }
}

class SellerTransaction extends DataClass
    implements Insertable<SellerTransaction> {
  final String id;
  final String sellerId;
  final String? invoiceId;
  final String? requestId;
  final String? requestHash;
  final String? openingBalanceSellerId;
  final String entryType;
  final String amount;
  final String occurredOn;
  final String? notes;
  final String createdByUserId;
  final String createdAt;
  const SellerTransaction(
      {required this.id,
      required this.sellerId,
      this.invoiceId,
      this.requestId,
      this.requestHash,
      this.openingBalanceSellerId,
      required this.entryType,
      required this.amount,
      required this.occurredOn,
      this.notes,
      required this.createdByUserId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['seller_id'] = Variable<String>(sellerId);
    if (!nullToAbsent || invoiceId != null) {
      map['invoice_id'] = Variable<String>(invoiceId);
    }
    if (!nullToAbsent || requestId != null) {
      map['request_id'] = Variable<String>(requestId);
    }
    if (!nullToAbsent || requestHash != null) {
      map['request_hash'] = Variable<String>(requestHash);
    }
    if (!nullToAbsent || openingBalanceSellerId != null) {
      map['opening_balance_seller_id'] =
          Variable<String>(openingBalanceSellerId);
    }
    map['entry_type'] = Variable<String>(entryType);
    map['amount'] = Variable<String>(amount);
    map['occurred_on'] = Variable<String>(occurredOn);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SellerTransactionsCompanion toCompanion(bool nullToAbsent) {
    return SellerTransactionsCompanion(
      id: Value(id),
      sellerId: Value(sellerId),
      invoiceId: invoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceId),
      requestId: requestId == null && nullToAbsent
          ? const Value.absent()
          : Value(requestId),
      requestHash: requestHash == null && nullToAbsent
          ? const Value.absent()
          : Value(requestHash),
      openingBalanceSellerId: openingBalanceSellerId == null && nullToAbsent
          ? const Value.absent()
          : Value(openingBalanceSellerId),
      entryType: Value(entryType),
      amount: Value(amount),
      occurredOn: Value(occurredOn),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdByUserId: Value(createdByUserId),
      createdAt: Value(createdAt),
    );
  }

  factory SellerTransaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SellerTransaction(
      id: serializer.fromJson<String>(json['id']),
      sellerId: serializer.fromJson<String>(json['sellerId']),
      invoiceId: serializer.fromJson<String?>(json['invoiceId']),
      requestId: serializer.fromJson<String?>(json['requestId']),
      requestHash: serializer.fromJson<String?>(json['requestHash']),
      openingBalanceSellerId:
          serializer.fromJson<String?>(json['openingBalanceSellerId']),
      entryType: serializer.fromJson<String>(json['entryType']),
      amount: serializer.fromJson<String>(json['amount']),
      occurredOn: serializer.fromJson<String>(json['occurredOn']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sellerId': serializer.toJson<String>(sellerId),
      'invoiceId': serializer.toJson<String?>(invoiceId),
      'requestId': serializer.toJson<String?>(requestId),
      'requestHash': serializer.toJson<String?>(requestHash),
      'openingBalanceSellerId':
          serializer.toJson<String?>(openingBalanceSellerId),
      'entryType': serializer.toJson<String>(entryType),
      'amount': serializer.toJson<String>(amount),
      'occurredOn': serializer.toJson<String>(occurredOn),
      'notes': serializer.toJson<String?>(notes),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  SellerTransaction copyWith(
          {String? id,
          String? sellerId,
          Value<String?> invoiceId = const Value.absent(),
          Value<String?> requestId = const Value.absent(),
          Value<String?> requestHash = const Value.absent(),
          Value<String?> openingBalanceSellerId = const Value.absent(),
          String? entryType,
          String? amount,
          String? occurredOn,
          Value<String?> notes = const Value.absent(),
          String? createdByUserId,
          String? createdAt}) =>
      SellerTransaction(
        id: id ?? this.id,
        sellerId: sellerId ?? this.sellerId,
        invoiceId: invoiceId.present ? invoiceId.value : this.invoiceId,
        requestId: requestId.present ? requestId.value : this.requestId,
        requestHash: requestHash.present ? requestHash.value : this.requestHash,
        openingBalanceSellerId: openingBalanceSellerId.present
            ? openingBalanceSellerId.value
            : this.openingBalanceSellerId,
        entryType: entryType ?? this.entryType,
        amount: amount ?? this.amount,
        occurredOn: occurredOn ?? this.occurredOn,
        notes: notes.present ? notes.value : this.notes,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        createdAt: createdAt ?? this.createdAt,
      );
  SellerTransaction copyWithCompanion(SellerTransactionsCompanion data) {
    return SellerTransaction(
      id: data.id.present ? data.id.value : this.id,
      sellerId: data.sellerId.present ? data.sellerId.value : this.sellerId,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      requestHash:
          data.requestHash.present ? data.requestHash.value : this.requestHash,
      openingBalanceSellerId: data.openingBalanceSellerId.present
          ? data.openingBalanceSellerId.value
          : this.openingBalanceSellerId,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      amount: data.amount.present ? data.amount.value : this.amount,
      occurredOn:
          data.occurredOn.present ? data.occurredOn.value : this.occurredOn,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SellerTransaction(')
          ..write('id: $id, ')
          ..write('sellerId: $sellerId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('requestId: $requestId, ')
          ..write('requestHash: $requestHash, ')
          ..write('openingBalanceSellerId: $openingBalanceSellerId, ')
          ..write('entryType: $entryType, ')
          ..write('amount: $amount, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sellerId,
      invoiceId,
      requestId,
      requestHash,
      openingBalanceSellerId,
      entryType,
      amount,
      occurredOn,
      notes,
      createdByUserId,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SellerTransaction &&
          other.id == this.id &&
          other.sellerId == this.sellerId &&
          other.invoiceId == this.invoiceId &&
          other.requestId == this.requestId &&
          other.requestHash == this.requestHash &&
          other.openingBalanceSellerId == this.openingBalanceSellerId &&
          other.entryType == this.entryType &&
          other.amount == this.amount &&
          other.occurredOn == this.occurredOn &&
          other.notes == this.notes &&
          other.createdByUserId == this.createdByUserId &&
          other.createdAt == this.createdAt);
}

class SellerTransactionsCompanion extends UpdateCompanion<SellerTransaction> {
  final Value<String> id;
  final Value<String> sellerId;
  final Value<String?> invoiceId;
  final Value<String?> requestId;
  final Value<String?> requestHash;
  final Value<String?> openingBalanceSellerId;
  final Value<String> entryType;
  final Value<String> amount;
  final Value<String> occurredOn;
  final Value<String?> notes;
  final Value<String> createdByUserId;
  final Value<String> createdAt;
  final Value<int> rowid;
  const SellerTransactionsCompanion({
    this.id = const Value.absent(),
    this.sellerId = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.requestId = const Value.absent(),
    this.requestHash = const Value.absent(),
    this.openingBalanceSellerId = const Value.absent(),
    this.entryType = const Value.absent(),
    this.amount = const Value.absent(),
    this.occurredOn = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SellerTransactionsCompanion.insert({
    required String id,
    required String sellerId,
    this.invoiceId = const Value.absent(),
    this.requestId = const Value.absent(),
    this.requestHash = const Value.absent(),
    this.openingBalanceSellerId = const Value.absent(),
    required String entryType,
    required String amount,
    required String occurredOn,
    this.notes = const Value.absent(),
    required String createdByUserId,
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sellerId = Value(sellerId),
        entryType = Value(entryType),
        amount = Value(amount),
        occurredOn = Value(occurredOn),
        createdByUserId = Value(createdByUserId),
        createdAt = Value(createdAt);
  static Insertable<SellerTransaction> custom({
    Expression<String>? id,
    Expression<String>? sellerId,
    Expression<String>? invoiceId,
    Expression<String>? requestId,
    Expression<String>? requestHash,
    Expression<String>? openingBalanceSellerId,
    Expression<String>? entryType,
    Expression<String>? amount,
    Expression<String>? occurredOn,
    Expression<String>? notes,
    Expression<String>? createdByUserId,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sellerId != null) 'seller_id': sellerId,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (requestId != null) 'request_id': requestId,
      if (requestHash != null) 'request_hash': requestHash,
      if (openingBalanceSellerId != null)
        'opening_balance_seller_id': openingBalanceSellerId,
      if (entryType != null) 'entry_type': entryType,
      if (amount != null) 'amount': amount,
      if (occurredOn != null) 'occurred_on': occurredOn,
      if (notes != null) 'notes': notes,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SellerTransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sellerId,
      Value<String?>? invoiceId,
      Value<String?>? requestId,
      Value<String?>? requestHash,
      Value<String?>? openingBalanceSellerId,
      Value<String>? entryType,
      Value<String>? amount,
      Value<String>? occurredOn,
      Value<String?>? notes,
      Value<String>? createdByUserId,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return SellerTransactionsCompanion(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      invoiceId: invoiceId ?? this.invoiceId,
      requestId: requestId ?? this.requestId,
      requestHash: requestHash ?? this.requestHash,
      openingBalanceSellerId:
          openingBalanceSellerId ?? this.openingBalanceSellerId,
      entryType: entryType ?? this.entryType,
      amount: amount ?? this.amount,
      occurredOn: occurredOn ?? this.occurredOn,
      notes: notes ?? this.notes,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sellerId.present) {
      map['seller_id'] = Variable<String>(sellerId.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (requestHash.present) {
      map['request_hash'] = Variable<String>(requestHash.value);
    }
    if (openingBalanceSellerId.present) {
      map['opening_balance_seller_id'] =
          Variable<String>(openingBalanceSellerId.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (occurredOn.present) {
      map['occurred_on'] = Variable<String>(occurredOn.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SellerTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('sellerId: $sellerId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('requestId: $requestId, ')
          ..write('requestHash: $requestHash, ')
          ..write('openingBalanceSellerId: $openingBalanceSellerId, ')
          ..write('entryType: $entryType, ')
          ..write('amount: $amount, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompanyProfilesTable extends CompanyProfiles
    with TableInfo<$CompanyProfilesTable, CompanyProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompanyProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
      'city', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stateCodeMeta =
      const VerificationMeta('stateCode');
  @override
  late final GeneratedColumn<String> stateCode = GeneratedColumn<String>(
      'state_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gstinMeta = const VerificationMeta('gstin');
  @override
  late final GeneratedColumn<String> gstin = GeneratedColumn<String>(
      'gstin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bankNameMeta =
      const VerificationMeta('bankName');
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
      'bank_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bankAccountMeta =
      const VerificationMeta('bankAccount');
  @override
  late final GeneratedColumn<String> bankAccount = GeneratedColumn<String>(
      'bank_account', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bankIfscMeta =
      const VerificationMeta('bankIfsc');
  @override
  late final GeneratedColumn<String> bankIfsc = GeneratedColumn<String>(
      'bank_ifsc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bankBranchMeta =
      const VerificationMeta('bankBranch');
  @override
  late final GeneratedColumn<String> bankBranch = GeneratedColumn<String>(
      'bank_branch', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jurisdictionMeta =
      const VerificationMeta('jurisdiction');
  @override
  late final GeneratedColumn<String> jurisdiction = GeneratedColumn<String>(
      'jurisdiction', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        address,
        city,
        state,
        stateCode,
        gstin,
        phone,
        email,
        bankName,
        bankAccount,
        bankIfsc,
        bankBranch,
        jurisdiction,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'company_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<CompanyProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('city')) {
      context.handle(
          _cityMeta, city.isAcceptableOrUnknown(data['city']!, _cityMeta));
    } else if (isInserting) {
      context.missing(_cityMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('state_code')) {
      context.handle(_stateCodeMeta,
          stateCode.isAcceptableOrUnknown(data['state_code']!, _stateCodeMeta));
    } else if (isInserting) {
      context.missing(_stateCodeMeta);
    }
    if (data.containsKey('gstin')) {
      context.handle(
          _gstinMeta, gstin.isAcceptableOrUnknown(data['gstin']!, _gstinMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('bank_name')) {
      context.handle(_bankNameMeta,
          bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta));
    }
    if (data.containsKey('bank_account')) {
      context.handle(
          _bankAccountMeta,
          bankAccount.isAcceptableOrUnknown(
              data['bank_account']!, _bankAccountMeta));
    }
    if (data.containsKey('bank_ifsc')) {
      context.handle(_bankIfscMeta,
          bankIfsc.isAcceptableOrUnknown(data['bank_ifsc']!, _bankIfscMeta));
    }
    if (data.containsKey('bank_branch')) {
      context.handle(
          _bankBranchMeta,
          bankBranch.isAcceptableOrUnknown(
              data['bank_branch']!, _bankBranchMeta));
    }
    if (data.containsKey('jurisdiction')) {
      context.handle(
          _jurisdictionMeta,
          jurisdiction.isAcceptableOrUnknown(
              data['jurisdiction']!, _jurisdictionMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompanyProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompanyProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      city: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      stateCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state_code'])!,
      gstin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gstin']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      bankName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_name']),
      bankAccount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_account']),
      bankIfsc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_ifsc']),
      bankBranch: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_branch']),
      jurisdiction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}jurisdiction']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CompanyProfilesTable createAlias(String alias) {
    return $CompanyProfilesTable(attachedDatabase, alias);
  }
}

class CompanyProfile extends DataClass implements Insertable<CompanyProfile> {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String stateCode;
  final String? gstin;
  final String? phone;
  final String? email;
  final String? bankName;
  final String? bankAccount;
  final String? bankIfsc;
  final String? bankBranch;
  final String? jurisdiction;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  const CompanyProfile(
      {required this.id,
      required this.name,
      required this.address,
      required this.city,
      required this.state,
      required this.stateCode,
      this.gstin,
      this.phone,
      this.email,
      this.bankName,
      this.bankAccount,
      this.bankIfsc,
      this.bankBranch,
      this.jurisdiction,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['city'] = Variable<String>(city);
    map['state'] = Variable<String>(state);
    map['state_code'] = Variable<String>(stateCode);
    if (!nullToAbsent || gstin != null) {
      map['gstin'] = Variable<String>(gstin);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || bankAccount != null) {
      map['bank_account'] = Variable<String>(bankAccount);
    }
    if (!nullToAbsent || bankIfsc != null) {
      map['bank_ifsc'] = Variable<String>(bankIfsc);
    }
    if (!nullToAbsent || bankBranch != null) {
      map['bank_branch'] = Variable<String>(bankBranch);
    }
    if (!nullToAbsent || jurisdiction != null) {
      map['jurisdiction'] = Variable<String>(jurisdiction);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CompanyProfilesCompanion toCompanion(bool nullToAbsent) {
    return CompanyProfilesCompanion(
      id: Value(id),
      name: Value(name),
      address: Value(address),
      city: Value(city),
      state: Value(state),
      stateCode: Value(stateCode),
      gstin:
          gstin == null && nullToAbsent ? const Value.absent() : Value(gstin),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      bankAccount: bankAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(bankAccount),
      bankIfsc: bankIfsc == null && nullToAbsent
          ? const Value.absent()
          : Value(bankIfsc),
      bankBranch: bankBranch == null && nullToAbsent
          ? const Value.absent()
          : Value(bankBranch),
      jurisdiction: jurisdiction == null && nullToAbsent
          ? const Value.absent()
          : Value(jurisdiction),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CompanyProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompanyProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      city: serializer.fromJson<String>(json['city']),
      state: serializer.fromJson<String>(json['state']),
      stateCode: serializer.fromJson<String>(json['stateCode']),
      gstin: serializer.fromJson<String?>(json['gstin']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      bankAccount: serializer.fromJson<String?>(json['bankAccount']),
      bankIfsc: serializer.fromJson<String?>(json['bankIfsc']),
      bankBranch: serializer.fromJson<String?>(json['bankBranch']),
      jurisdiction: serializer.fromJson<String?>(json['jurisdiction']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'city': serializer.toJson<String>(city),
      'state': serializer.toJson<String>(state),
      'stateCode': serializer.toJson<String>(stateCode),
      'gstin': serializer.toJson<String?>(gstin),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'bankName': serializer.toJson<String?>(bankName),
      'bankAccount': serializer.toJson<String?>(bankAccount),
      'bankIfsc': serializer.toJson<String?>(bankIfsc),
      'bankBranch': serializer.toJson<String?>(bankBranch),
      'jurisdiction': serializer.toJson<String?>(jurisdiction),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  CompanyProfile copyWith(
          {String? id,
          String? name,
          String? address,
          String? city,
          String? state,
          String? stateCode,
          Value<String?> gstin = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> email = const Value.absent(),
          Value<String?> bankName = const Value.absent(),
          Value<String?> bankAccount = const Value.absent(),
          Value<String?> bankIfsc = const Value.absent(),
          Value<String?> bankBranch = const Value.absent(),
          Value<String?> jurisdiction = const Value.absent(),
          bool? isActive,
          String? createdAt,
          String? updatedAt}) =>
      CompanyProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        stateCode: stateCode ?? this.stateCode,
        gstin: gstin.present ? gstin.value : this.gstin,
        phone: phone.present ? phone.value : this.phone,
        email: email.present ? email.value : this.email,
        bankName: bankName.present ? bankName.value : this.bankName,
        bankAccount: bankAccount.present ? bankAccount.value : this.bankAccount,
        bankIfsc: bankIfsc.present ? bankIfsc.value : this.bankIfsc,
        bankBranch: bankBranch.present ? bankBranch.value : this.bankBranch,
        jurisdiction:
            jurisdiction.present ? jurisdiction.value : this.jurisdiction,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CompanyProfile copyWithCompanion(CompanyProfilesCompanion data) {
    return CompanyProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      stateCode: data.stateCode.present ? data.stateCode.value : this.stateCode,
      gstin: data.gstin.present ? data.gstin.value : this.gstin,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      bankAccount:
          data.bankAccount.present ? data.bankAccount.value : this.bankAccount,
      bankIfsc: data.bankIfsc.present ? data.bankIfsc.value : this.bankIfsc,
      bankBranch:
          data.bankBranch.present ? data.bankBranch.value : this.bankBranch,
      jurisdiction: data.jurisdiction.present
          ? data.jurisdiction.value
          : this.jurisdiction,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompanyProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('stateCode: $stateCode, ')
          ..write('gstin: $gstin, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('bankName: $bankName, ')
          ..write('bankAccount: $bankAccount, ')
          ..write('bankIfsc: $bankIfsc, ')
          ..write('bankBranch: $bankBranch, ')
          ..write('jurisdiction: $jurisdiction, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      address,
      city,
      state,
      stateCode,
      gstin,
      phone,
      email,
      bankName,
      bankAccount,
      bankIfsc,
      bankBranch,
      jurisdiction,
      isActive,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompanyProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.city == this.city &&
          other.state == this.state &&
          other.stateCode == this.stateCode &&
          other.gstin == this.gstin &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.bankName == this.bankName &&
          other.bankAccount == this.bankAccount &&
          other.bankIfsc == this.bankIfsc &&
          other.bankBranch == this.bankBranch &&
          other.jurisdiction == this.jurisdiction &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CompanyProfilesCompanion extends UpdateCompanion<CompanyProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> address;
  final Value<String> city;
  final Value<String> state;
  final Value<String> stateCode;
  final Value<String?> gstin;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<String?> bankName;
  final Value<String?> bankAccount;
  final Value<String?> bankIfsc;
  final Value<String?> bankBranch;
  final Value<String?> jurisdiction;
  final Value<bool> isActive;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CompanyProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.stateCode = const Value.absent(),
    this.gstin = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankAccount = const Value.absent(),
    this.bankIfsc = const Value.absent(),
    this.bankBranch = const Value.absent(),
    this.jurisdiction = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompanyProfilesCompanion.insert({
    required String id,
    required String name,
    required String address,
    required String city,
    required String state,
    required String stateCode,
    this.gstin = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankAccount = const Value.absent(),
    this.bankIfsc = const Value.absent(),
    this.bankBranch = const Value.absent(),
    this.jurisdiction = const Value.absent(),
    this.isActive = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        address = Value(address),
        city = Value(city),
        state = Value(state),
        stateCode = Value(stateCode),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CompanyProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? city,
    Expression<String>? state,
    Expression<String>? stateCode,
    Expression<String>? gstin,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? bankName,
    Expression<String>? bankAccount,
    Expression<String>? bankIfsc,
    Expression<String>? bankBranch,
    Expression<String>? jurisdiction,
    Expression<bool>? isActive,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (stateCode != null) 'state_code': stateCode,
      if (gstin != null) 'gstin': gstin,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (bankName != null) 'bank_name': bankName,
      if (bankAccount != null) 'bank_account': bankAccount,
      if (bankIfsc != null) 'bank_ifsc': bankIfsc,
      if (bankBranch != null) 'bank_branch': bankBranch,
      if (jurisdiction != null) 'jurisdiction': jurisdiction,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompanyProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? address,
      Value<String>? city,
      Value<String>? state,
      Value<String>? stateCode,
      Value<String?>? gstin,
      Value<String?>? phone,
      Value<String?>? email,
      Value<String?>? bankName,
      Value<String?>? bankAccount,
      Value<String?>? bankIfsc,
      Value<String?>? bankBranch,
      Value<String?>? jurisdiction,
      Value<bool>? isActive,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return CompanyProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      stateCode: stateCode ?? this.stateCode,
      gstin: gstin ?? this.gstin,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankBranch: bankBranch ?? this.bankBranch,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (stateCode.present) {
      map['state_code'] = Variable<String>(stateCode.value);
    }
    if (gstin.present) {
      map['gstin'] = Variable<String>(gstin.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (bankAccount.present) {
      map['bank_account'] = Variable<String>(bankAccount.value);
    }
    if (bankIfsc.present) {
      map['bank_ifsc'] = Variable<String>(bankIfsc.value);
    }
    if (bankBranch.present) {
      map['bank_branch'] = Variable<String>(bankBranch.value);
    }
    if (jurisdiction.present) {
      map['jurisdiction'] = Variable<String>(jurisdiction.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompanyProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('stateCode: $stateCode, ')
          ..write('gstin: $gstin, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('bankName: $bankName, ')
          ..write('bankAccount: $bankAccount, ')
          ..write('bankIfsc: $bankIfsc, ')
          ..write('bankBranch: $bankBranch, ')
          ..write('jurisdiction: $jurisdiction, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoiceItemsTable extends InvoiceItems
    with TableInfo<$InvoiceItemsTable, InvoiceItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _invoiceIdMeta =
      const VerificationMeta('invoiceId');
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
      'invoice_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES invoices (id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _lineNumberMeta =
      const VerificationMeta('lineNumber');
  @override
  late final GeneratedColumn<int> lineNumber = GeneratedColumn<int>(
      'line_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productCodeMeta =
      const VerificationMeta('productCode');
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
      'product_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyMeta =
      const VerificationMeta('company');
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
      'company', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
      'quantity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pricingModeMeta =
      const VerificationMeta('pricingMode');
  @override
  late final GeneratedColumn<String> pricingMode = GeneratedColumn<String>(
      'pricing_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _enteredUnitPriceMeta =
      const VerificationMeta('enteredUnitPrice');
  @override
  late final GeneratedColumn<String> enteredUnitPrice = GeneratedColumn<String>(
      'entered_unit_price', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceExclTaxMeta =
      const VerificationMeta('unitPriceExclTax');
  @override
  late final GeneratedColumn<String> unitPriceExclTax = GeneratedColumn<String>(
      'unit_price_excl_tax', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceInclTaxMeta =
      const VerificationMeta('unitPriceInclTax');
  @override
  late final GeneratedColumn<String> unitPriceInclTax = GeneratedColumn<String>(
      'unit_price_incl_tax', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gstRateMeta =
      const VerificationMeta('gstRate');
  @override
  late final GeneratedColumn<String> gstRate = GeneratedColumn<String>(
      'gst_rate', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cgstRateMeta =
      const VerificationMeta('cgstRate');
  @override
  late final GeneratedColumn<String> cgstRate = GeneratedColumn<String>(
      'cgst_rate', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sgstRateMeta =
      const VerificationMeta('sgstRate');
  @override
  late final GeneratedColumn<String> sgstRate = GeneratedColumn<String>(
      'sgst_rate', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _igstRateMeta =
      const VerificationMeta('igstRate');
  @override
  late final GeneratedColumn<String> igstRate = GeneratedColumn<String>(
      'igst_rate', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _discountPercentMeta =
      const VerificationMeta('discountPercent');
  @override
  late final GeneratedColumn<String> discountPercent = GeneratedColumn<String>(
      'discount_percent', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _discountAmountMeta =
      const VerificationMeta('discountAmount');
  @override
  late final GeneratedColumn<String> discountAmount = GeneratedColumn<String>(
      'discount_amount', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taxableAmountMeta =
      const VerificationMeta('taxableAmount');
  @override
  late final GeneratedColumn<String> taxableAmount = GeneratedColumn<String>(
      'taxable_amount', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gstAmountMeta =
      const VerificationMeta('gstAmount');
  @override
  late final GeneratedColumn<String> gstAmount = GeneratedColumn<String>(
      'gst_amount', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cgstAmountMeta =
      const VerificationMeta('cgstAmount');
  @override
  late final GeneratedColumn<String> cgstAmount = GeneratedColumn<String>(
      'cgst_amount', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sgstAmountMeta =
      const VerificationMeta('sgstAmount');
  @override
  late final GeneratedColumn<String> sgstAmount = GeneratedColumn<String>(
      'sgst_amount', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _igstAmountMeta =
      const VerificationMeta('igstAmount');
  @override
  late final GeneratedColumn<String> igstAmount = GeneratedColumn<String>(
      'igst_amount', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lineTotalMeta =
      const VerificationMeta('lineTotal');
  @override
  late final GeneratedColumn<String> lineTotal = GeneratedColumn<String>(
      'line_total', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        invoiceId,
        productId,
        lineNumber,
        productName,
        productCode,
        company,
        category,
        quantity,
        pricingMode,
        enteredUnitPrice,
        unitPriceExclTax,
        unitPriceInclTax,
        gstRate,
        cgstRate,
        sgstRate,
        igstRate,
        discountPercent,
        discountAmount,
        taxableAmount,
        gstAmount,
        cgstAmount,
        sgstAmount,
        igstAmount,
        lineTotal
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_items';
  @override
  VerificationContext validateIntegrity(Insertable<InvoiceItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(_invoiceIdMeta,
          invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta));
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('line_number')) {
      context.handle(
          _lineNumberMeta,
          lineNumber.isAcceptableOrUnknown(
              data['line_number']!, _lineNumberMeta));
    } else if (isInserting) {
      context.missing(_lineNumberMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
          _productCodeMeta,
          productCode.isAcceptableOrUnknown(
              data['product_code']!, _productCodeMeta));
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('company')) {
      context.handle(_companyMeta,
          company.isAcceptableOrUnknown(data['company']!, _companyMeta));
    } else if (isInserting) {
      context.missing(_companyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('pricing_mode')) {
      context.handle(
          _pricingModeMeta,
          pricingMode.isAcceptableOrUnknown(
              data['pricing_mode']!, _pricingModeMeta));
    } else if (isInserting) {
      context.missing(_pricingModeMeta);
    }
    if (data.containsKey('entered_unit_price')) {
      context.handle(
          _enteredUnitPriceMeta,
          enteredUnitPrice.isAcceptableOrUnknown(
              data['entered_unit_price']!, _enteredUnitPriceMeta));
    } else if (isInserting) {
      context.missing(_enteredUnitPriceMeta);
    }
    if (data.containsKey('unit_price_excl_tax')) {
      context.handle(
          _unitPriceExclTaxMeta,
          unitPriceExclTax.isAcceptableOrUnknown(
              data['unit_price_excl_tax']!, _unitPriceExclTaxMeta));
    } else if (isInserting) {
      context.missing(_unitPriceExclTaxMeta);
    }
    if (data.containsKey('unit_price_incl_tax')) {
      context.handle(
          _unitPriceInclTaxMeta,
          unitPriceInclTax.isAcceptableOrUnknown(
              data['unit_price_incl_tax']!, _unitPriceInclTaxMeta));
    } else if (isInserting) {
      context.missing(_unitPriceInclTaxMeta);
    }
    if (data.containsKey('gst_rate')) {
      context.handle(_gstRateMeta,
          gstRate.isAcceptableOrUnknown(data['gst_rate']!, _gstRateMeta));
    } else if (isInserting) {
      context.missing(_gstRateMeta);
    }
    if (data.containsKey('cgst_rate')) {
      context.handle(_cgstRateMeta,
          cgstRate.isAcceptableOrUnknown(data['cgst_rate']!, _cgstRateMeta));
    } else if (isInserting) {
      context.missing(_cgstRateMeta);
    }
    if (data.containsKey('sgst_rate')) {
      context.handle(_sgstRateMeta,
          sgstRate.isAcceptableOrUnknown(data['sgst_rate']!, _sgstRateMeta));
    } else if (isInserting) {
      context.missing(_sgstRateMeta);
    }
    if (data.containsKey('igst_rate')) {
      context.handle(_igstRateMeta,
          igstRate.isAcceptableOrUnknown(data['igst_rate']!, _igstRateMeta));
    } else if (isInserting) {
      context.missing(_igstRateMeta);
    }
    if (data.containsKey('discount_percent')) {
      context.handle(
          _discountPercentMeta,
          discountPercent.isAcceptableOrUnknown(
              data['discount_percent']!, _discountPercentMeta));
    } else if (isInserting) {
      context.missing(_discountPercentMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
          _discountAmountMeta,
          discountAmount.isAcceptableOrUnknown(
              data['discount_amount']!, _discountAmountMeta));
    } else if (isInserting) {
      context.missing(_discountAmountMeta);
    }
    if (data.containsKey('taxable_amount')) {
      context.handle(
          _taxableAmountMeta,
          taxableAmount.isAcceptableOrUnknown(
              data['taxable_amount']!, _taxableAmountMeta));
    } else if (isInserting) {
      context.missing(_taxableAmountMeta);
    }
    if (data.containsKey('gst_amount')) {
      context.handle(_gstAmountMeta,
          gstAmount.isAcceptableOrUnknown(data['gst_amount']!, _gstAmountMeta));
    } else if (isInserting) {
      context.missing(_gstAmountMeta);
    }
    if (data.containsKey('cgst_amount')) {
      context.handle(
          _cgstAmountMeta,
          cgstAmount.isAcceptableOrUnknown(
              data['cgst_amount']!, _cgstAmountMeta));
    } else if (isInserting) {
      context.missing(_cgstAmountMeta);
    }
    if (data.containsKey('sgst_amount')) {
      context.handle(
          _sgstAmountMeta,
          sgstAmount.isAcceptableOrUnknown(
              data['sgst_amount']!, _sgstAmountMeta));
    } else if (isInserting) {
      context.missing(_sgstAmountMeta);
    }
    if (data.containsKey('igst_amount')) {
      context.handle(
          _igstAmountMeta,
          igstAmount.isAcceptableOrUnknown(
              data['igst_amount']!, _igstAmountMeta));
    } else if (isInserting) {
      context.missing(_igstAmountMeta);
    }
    if (data.containsKey('line_total')) {
      context.handle(_lineTotalMeta,
          lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta));
    } else if (isInserting) {
      context.missing(_lineTotalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      invoiceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      lineNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}line_number'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      productCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_code'])!,
      company: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quantity'])!,
      pricingMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pricing_mode'])!,
      enteredUnitPrice: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}entered_unit_price'])!,
      unitPriceExclTax: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}unit_price_excl_tax'])!,
      unitPriceInclTax: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}unit_price_incl_tax'])!,
      gstRate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gst_rate'])!,
      cgstRate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cgst_rate'])!,
      sgstRate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sgst_rate'])!,
      igstRate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}igst_rate'])!,
      discountPercent: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}discount_percent'])!,
      discountAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}discount_amount'])!,
      taxableAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}taxable_amount'])!,
      gstAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gst_amount'])!,
      cgstAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cgst_amount'])!,
      sgstAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sgst_amount'])!,
      igstAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}igst_amount'])!,
      lineTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}line_total'])!,
    );
  }

  @override
  $InvoiceItemsTable createAlias(String alias) {
    return $InvoiceItemsTable(attachedDatabase, alias);
  }
}

class InvoiceItem extends DataClass implements Insertable<InvoiceItem> {
  final String id;
  final String invoiceId;
  final String productId;
  final int lineNumber;
  final String productName;
  final String productCode;
  final String company;
  final String category;
  final String quantity;
  final String pricingMode;
  final String enteredUnitPrice;
  final String unitPriceExclTax;
  final String unitPriceInclTax;
  final String gstRate;
  final String cgstRate;
  final String sgstRate;
  final String igstRate;
  final String discountPercent;
  final String discountAmount;
  final String taxableAmount;
  final String gstAmount;
  final String cgstAmount;
  final String sgstAmount;
  final String igstAmount;
  final String lineTotal;
  const InvoiceItem(
      {required this.id,
      required this.invoiceId,
      required this.productId,
      required this.lineNumber,
      required this.productName,
      required this.productCode,
      required this.company,
      required this.category,
      required this.quantity,
      required this.pricingMode,
      required this.enteredUnitPrice,
      required this.unitPriceExclTax,
      required this.unitPriceInclTax,
      required this.gstRate,
      required this.cgstRate,
      required this.sgstRate,
      required this.igstRate,
      required this.discountPercent,
      required this.discountAmount,
      required this.taxableAmount,
      required this.gstAmount,
      required this.cgstAmount,
      required this.sgstAmount,
      required this.igstAmount,
      required this.lineTotal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['product_id'] = Variable<String>(productId);
    map['line_number'] = Variable<int>(lineNumber);
    map['product_name'] = Variable<String>(productName);
    map['product_code'] = Variable<String>(productCode);
    map['company'] = Variable<String>(company);
    map['category'] = Variable<String>(category);
    map['quantity'] = Variable<String>(quantity);
    map['pricing_mode'] = Variable<String>(pricingMode);
    map['entered_unit_price'] = Variable<String>(enteredUnitPrice);
    map['unit_price_excl_tax'] = Variable<String>(unitPriceExclTax);
    map['unit_price_incl_tax'] = Variable<String>(unitPriceInclTax);
    map['gst_rate'] = Variable<String>(gstRate);
    map['cgst_rate'] = Variable<String>(cgstRate);
    map['sgst_rate'] = Variable<String>(sgstRate);
    map['igst_rate'] = Variable<String>(igstRate);
    map['discount_percent'] = Variable<String>(discountPercent);
    map['discount_amount'] = Variable<String>(discountAmount);
    map['taxable_amount'] = Variable<String>(taxableAmount);
    map['gst_amount'] = Variable<String>(gstAmount);
    map['cgst_amount'] = Variable<String>(cgstAmount);
    map['sgst_amount'] = Variable<String>(sgstAmount);
    map['igst_amount'] = Variable<String>(igstAmount);
    map['line_total'] = Variable<String>(lineTotal);
    return map;
  }

  InvoiceItemsCompanion toCompanion(bool nullToAbsent) {
    return InvoiceItemsCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      productId: Value(productId),
      lineNumber: Value(lineNumber),
      productName: Value(productName),
      productCode: Value(productCode),
      company: Value(company),
      category: Value(category),
      quantity: Value(quantity),
      pricingMode: Value(pricingMode),
      enteredUnitPrice: Value(enteredUnitPrice),
      unitPriceExclTax: Value(unitPriceExclTax),
      unitPriceInclTax: Value(unitPriceInclTax),
      gstRate: Value(gstRate),
      cgstRate: Value(cgstRate),
      sgstRate: Value(sgstRate),
      igstRate: Value(igstRate),
      discountPercent: Value(discountPercent),
      discountAmount: Value(discountAmount),
      taxableAmount: Value(taxableAmount),
      gstAmount: Value(gstAmount),
      cgstAmount: Value(cgstAmount),
      sgstAmount: Value(sgstAmount),
      igstAmount: Value(igstAmount),
      lineTotal: Value(lineTotal),
    );
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceItem(
      id: serializer.fromJson<String>(json['id']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      productId: serializer.fromJson<String>(json['productId']),
      lineNumber: serializer.fromJson<int>(json['lineNumber']),
      productName: serializer.fromJson<String>(json['productName']),
      productCode: serializer.fromJson<String>(json['productCode']),
      company: serializer.fromJson<String>(json['company']),
      category: serializer.fromJson<String>(json['category']),
      quantity: serializer.fromJson<String>(json['quantity']),
      pricingMode: serializer.fromJson<String>(json['pricingMode']),
      enteredUnitPrice: serializer.fromJson<String>(json['enteredUnitPrice']),
      unitPriceExclTax: serializer.fromJson<String>(json['unitPriceExclTax']),
      unitPriceInclTax: serializer.fromJson<String>(json['unitPriceInclTax']),
      gstRate: serializer.fromJson<String>(json['gstRate']),
      cgstRate: serializer.fromJson<String>(json['cgstRate']),
      sgstRate: serializer.fromJson<String>(json['sgstRate']),
      igstRate: serializer.fromJson<String>(json['igstRate']),
      discountPercent: serializer.fromJson<String>(json['discountPercent']),
      discountAmount: serializer.fromJson<String>(json['discountAmount']),
      taxableAmount: serializer.fromJson<String>(json['taxableAmount']),
      gstAmount: serializer.fromJson<String>(json['gstAmount']),
      cgstAmount: serializer.fromJson<String>(json['cgstAmount']),
      sgstAmount: serializer.fromJson<String>(json['sgstAmount']),
      igstAmount: serializer.fromJson<String>(json['igstAmount']),
      lineTotal: serializer.fromJson<String>(json['lineTotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'productId': serializer.toJson<String>(productId),
      'lineNumber': serializer.toJson<int>(lineNumber),
      'productName': serializer.toJson<String>(productName),
      'productCode': serializer.toJson<String>(productCode),
      'company': serializer.toJson<String>(company),
      'category': serializer.toJson<String>(category),
      'quantity': serializer.toJson<String>(quantity),
      'pricingMode': serializer.toJson<String>(pricingMode),
      'enteredUnitPrice': serializer.toJson<String>(enteredUnitPrice),
      'unitPriceExclTax': serializer.toJson<String>(unitPriceExclTax),
      'unitPriceInclTax': serializer.toJson<String>(unitPriceInclTax),
      'gstRate': serializer.toJson<String>(gstRate),
      'cgstRate': serializer.toJson<String>(cgstRate),
      'sgstRate': serializer.toJson<String>(sgstRate),
      'igstRate': serializer.toJson<String>(igstRate),
      'discountPercent': serializer.toJson<String>(discountPercent),
      'discountAmount': serializer.toJson<String>(discountAmount),
      'taxableAmount': serializer.toJson<String>(taxableAmount),
      'gstAmount': serializer.toJson<String>(gstAmount),
      'cgstAmount': serializer.toJson<String>(cgstAmount),
      'sgstAmount': serializer.toJson<String>(sgstAmount),
      'igstAmount': serializer.toJson<String>(igstAmount),
      'lineTotal': serializer.toJson<String>(lineTotal),
    };
  }

  InvoiceItem copyWith(
          {String? id,
          String? invoiceId,
          String? productId,
          int? lineNumber,
          String? productName,
          String? productCode,
          String? company,
          String? category,
          String? quantity,
          String? pricingMode,
          String? enteredUnitPrice,
          String? unitPriceExclTax,
          String? unitPriceInclTax,
          String? gstRate,
          String? cgstRate,
          String? sgstRate,
          String? igstRate,
          String? discountPercent,
          String? discountAmount,
          String? taxableAmount,
          String? gstAmount,
          String? cgstAmount,
          String? sgstAmount,
          String? igstAmount,
          String? lineTotal}) =>
      InvoiceItem(
        id: id ?? this.id,
        invoiceId: invoiceId ?? this.invoiceId,
        productId: productId ?? this.productId,
        lineNumber: lineNumber ?? this.lineNumber,
        productName: productName ?? this.productName,
        productCode: productCode ?? this.productCode,
        company: company ?? this.company,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        pricingMode: pricingMode ?? this.pricingMode,
        enteredUnitPrice: enteredUnitPrice ?? this.enteredUnitPrice,
        unitPriceExclTax: unitPriceExclTax ?? this.unitPriceExclTax,
        unitPriceInclTax: unitPriceInclTax ?? this.unitPriceInclTax,
        gstRate: gstRate ?? this.gstRate,
        cgstRate: cgstRate ?? this.cgstRate,
        sgstRate: sgstRate ?? this.sgstRate,
        igstRate: igstRate ?? this.igstRate,
        discountPercent: discountPercent ?? this.discountPercent,
        discountAmount: discountAmount ?? this.discountAmount,
        taxableAmount: taxableAmount ?? this.taxableAmount,
        gstAmount: gstAmount ?? this.gstAmount,
        cgstAmount: cgstAmount ?? this.cgstAmount,
        sgstAmount: sgstAmount ?? this.sgstAmount,
        igstAmount: igstAmount ?? this.igstAmount,
        lineTotal: lineTotal ?? this.lineTotal,
      );
  InvoiceItem copyWithCompanion(InvoiceItemsCompanion data) {
    return InvoiceItem(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      productId: data.productId.present ? data.productId.value : this.productId,
      lineNumber:
          data.lineNumber.present ? data.lineNumber.value : this.lineNumber,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      productCode:
          data.productCode.present ? data.productCode.value : this.productCode,
      company: data.company.present ? data.company.value : this.company,
      category: data.category.present ? data.category.value : this.category,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      pricingMode:
          data.pricingMode.present ? data.pricingMode.value : this.pricingMode,
      enteredUnitPrice: data.enteredUnitPrice.present
          ? data.enteredUnitPrice.value
          : this.enteredUnitPrice,
      unitPriceExclTax: data.unitPriceExclTax.present
          ? data.unitPriceExclTax.value
          : this.unitPriceExclTax,
      unitPriceInclTax: data.unitPriceInclTax.present
          ? data.unitPriceInclTax.value
          : this.unitPriceInclTax,
      gstRate: data.gstRate.present ? data.gstRate.value : this.gstRate,
      cgstRate: data.cgstRate.present ? data.cgstRate.value : this.cgstRate,
      sgstRate: data.sgstRate.present ? data.sgstRate.value : this.sgstRate,
      igstRate: data.igstRate.present ? data.igstRate.value : this.igstRate,
      discountPercent: data.discountPercent.present
          ? data.discountPercent.value
          : this.discountPercent,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      taxableAmount: data.taxableAmount.present
          ? data.taxableAmount.value
          : this.taxableAmount,
      gstAmount: data.gstAmount.present ? data.gstAmount.value : this.gstAmount,
      cgstAmount:
          data.cgstAmount.present ? data.cgstAmount.value : this.cgstAmount,
      sgstAmount:
          data.sgstAmount.present ? data.sgstAmount.value : this.sgstAmount,
      igstAmount:
          data.igstAmount.present ? data.igstAmount.value : this.igstAmount,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItem(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('lineNumber: $lineNumber, ')
          ..write('productName: $productName, ')
          ..write('productCode: $productCode, ')
          ..write('company: $company, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('pricingMode: $pricingMode, ')
          ..write('enteredUnitPrice: $enteredUnitPrice, ')
          ..write('unitPriceExclTax: $unitPriceExclTax, ')
          ..write('unitPriceInclTax: $unitPriceInclTax, ')
          ..write('gstRate: $gstRate, ')
          ..write('cgstRate: $cgstRate, ')
          ..write('sgstRate: $sgstRate, ')
          ..write('igstRate: $igstRate, ')
          ..write('discountPercent: $discountPercent, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxableAmount: $taxableAmount, ')
          ..write('gstAmount: $gstAmount, ')
          ..write('cgstAmount: $cgstAmount, ')
          ..write('sgstAmount: $sgstAmount, ')
          ..write('igstAmount: $igstAmount, ')
          ..write('lineTotal: $lineTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        invoiceId,
        productId,
        lineNumber,
        productName,
        productCode,
        company,
        category,
        quantity,
        pricingMode,
        enteredUnitPrice,
        unitPriceExclTax,
        unitPriceInclTax,
        gstRate,
        cgstRate,
        sgstRate,
        igstRate,
        discountPercent,
        discountAmount,
        taxableAmount,
        gstAmount,
        cgstAmount,
        sgstAmount,
        igstAmount,
        lineTotal
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceItem &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.productId == this.productId &&
          other.lineNumber == this.lineNumber &&
          other.productName == this.productName &&
          other.productCode == this.productCode &&
          other.company == this.company &&
          other.category == this.category &&
          other.quantity == this.quantity &&
          other.pricingMode == this.pricingMode &&
          other.enteredUnitPrice == this.enteredUnitPrice &&
          other.unitPriceExclTax == this.unitPriceExclTax &&
          other.unitPriceInclTax == this.unitPriceInclTax &&
          other.gstRate == this.gstRate &&
          other.cgstRate == this.cgstRate &&
          other.sgstRate == this.sgstRate &&
          other.igstRate == this.igstRate &&
          other.discountPercent == this.discountPercent &&
          other.discountAmount == this.discountAmount &&
          other.taxableAmount == this.taxableAmount &&
          other.gstAmount == this.gstAmount &&
          other.cgstAmount == this.cgstAmount &&
          other.sgstAmount == this.sgstAmount &&
          other.igstAmount == this.igstAmount &&
          other.lineTotal == this.lineTotal);
}

class InvoiceItemsCompanion extends UpdateCompanion<InvoiceItem> {
  final Value<String> id;
  final Value<String> invoiceId;
  final Value<String> productId;
  final Value<int> lineNumber;
  final Value<String> productName;
  final Value<String> productCode;
  final Value<String> company;
  final Value<String> category;
  final Value<String> quantity;
  final Value<String> pricingMode;
  final Value<String> enteredUnitPrice;
  final Value<String> unitPriceExclTax;
  final Value<String> unitPriceInclTax;
  final Value<String> gstRate;
  final Value<String> cgstRate;
  final Value<String> sgstRate;
  final Value<String> igstRate;
  final Value<String> discountPercent;
  final Value<String> discountAmount;
  final Value<String> taxableAmount;
  final Value<String> gstAmount;
  final Value<String> cgstAmount;
  final Value<String> sgstAmount;
  final Value<String> igstAmount;
  final Value<String> lineTotal;
  final Value<int> rowid;
  const InvoiceItemsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.productId = const Value.absent(),
    this.lineNumber = const Value.absent(),
    this.productName = const Value.absent(),
    this.productCode = const Value.absent(),
    this.company = const Value.absent(),
    this.category = const Value.absent(),
    this.quantity = const Value.absent(),
    this.pricingMode = const Value.absent(),
    this.enteredUnitPrice = const Value.absent(),
    this.unitPriceExclTax = const Value.absent(),
    this.unitPriceInclTax = const Value.absent(),
    this.gstRate = const Value.absent(),
    this.cgstRate = const Value.absent(),
    this.sgstRate = const Value.absent(),
    this.igstRate = const Value.absent(),
    this.discountPercent = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxableAmount = const Value.absent(),
    this.gstAmount = const Value.absent(),
    this.cgstAmount = const Value.absent(),
    this.sgstAmount = const Value.absent(),
    this.igstAmount = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoiceItemsCompanion.insert({
    required String id,
    required String invoiceId,
    required String productId,
    required int lineNumber,
    required String productName,
    required String productCode,
    required String company,
    required String category,
    required String quantity,
    required String pricingMode,
    required String enteredUnitPrice,
    required String unitPriceExclTax,
    required String unitPriceInclTax,
    required String gstRate,
    required String cgstRate,
    required String sgstRate,
    required String igstRate,
    required String discountPercent,
    required String discountAmount,
    required String taxableAmount,
    required String gstAmount,
    required String cgstAmount,
    required String sgstAmount,
    required String igstAmount,
    required String lineTotal,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        invoiceId = Value(invoiceId),
        productId = Value(productId),
        lineNumber = Value(lineNumber),
        productName = Value(productName),
        productCode = Value(productCode),
        company = Value(company),
        category = Value(category),
        quantity = Value(quantity),
        pricingMode = Value(pricingMode),
        enteredUnitPrice = Value(enteredUnitPrice),
        unitPriceExclTax = Value(unitPriceExclTax),
        unitPriceInclTax = Value(unitPriceInclTax),
        gstRate = Value(gstRate),
        cgstRate = Value(cgstRate),
        sgstRate = Value(sgstRate),
        igstRate = Value(igstRate),
        discountPercent = Value(discountPercent),
        discountAmount = Value(discountAmount),
        taxableAmount = Value(taxableAmount),
        gstAmount = Value(gstAmount),
        cgstAmount = Value(cgstAmount),
        sgstAmount = Value(sgstAmount),
        igstAmount = Value(igstAmount),
        lineTotal = Value(lineTotal);
  static Insertable<InvoiceItem> custom({
    Expression<String>? id,
    Expression<String>? invoiceId,
    Expression<String>? productId,
    Expression<int>? lineNumber,
    Expression<String>? productName,
    Expression<String>? productCode,
    Expression<String>? company,
    Expression<String>? category,
    Expression<String>? quantity,
    Expression<String>? pricingMode,
    Expression<String>? enteredUnitPrice,
    Expression<String>? unitPriceExclTax,
    Expression<String>? unitPriceInclTax,
    Expression<String>? gstRate,
    Expression<String>? cgstRate,
    Expression<String>? sgstRate,
    Expression<String>? igstRate,
    Expression<String>? discountPercent,
    Expression<String>? discountAmount,
    Expression<String>? taxableAmount,
    Expression<String>? gstAmount,
    Expression<String>? cgstAmount,
    Expression<String>? sgstAmount,
    Expression<String>? igstAmount,
    Expression<String>? lineTotal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (productId != null) 'product_id': productId,
      if (lineNumber != null) 'line_number': lineNumber,
      if (productName != null) 'product_name': productName,
      if (productCode != null) 'product_code': productCode,
      if (company != null) 'company': company,
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (pricingMode != null) 'pricing_mode': pricingMode,
      if (enteredUnitPrice != null) 'entered_unit_price': enteredUnitPrice,
      if (unitPriceExclTax != null) 'unit_price_excl_tax': unitPriceExclTax,
      if (unitPriceInclTax != null) 'unit_price_incl_tax': unitPriceInclTax,
      if (gstRate != null) 'gst_rate': gstRate,
      if (cgstRate != null) 'cgst_rate': cgstRate,
      if (sgstRate != null) 'sgst_rate': sgstRate,
      if (igstRate != null) 'igst_rate': igstRate,
      if (discountPercent != null) 'discount_percent': discountPercent,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (taxableAmount != null) 'taxable_amount': taxableAmount,
      if (gstAmount != null) 'gst_amount': gstAmount,
      if (cgstAmount != null) 'cgst_amount': cgstAmount,
      if (sgstAmount != null) 'sgst_amount': sgstAmount,
      if (igstAmount != null) 'igst_amount': igstAmount,
      if (lineTotal != null) 'line_total': lineTotal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoiceItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? invoiceId,
      Value<String>? productId,
      Value<int>? lineNumber,
      Value<String>? productName,
      Value<String>? productCode,
      Value<String>? company,
      Value<String>? category,
      Value<String>? quantity,
      Value<String>? pricingMode,
      Value<String>? enteredUnitPrice,
      Value<String>? unitPriceExclTax,
      Value<String>? unitPriceInclTax,
      Value<String>? gstRate,
      Value<String>? cgstRate,
      Value<String>? sgstRate,
      Value<String>? igstRate,
      Value<String>? discountPercent,
      Value<String>? discountAmount,
      Value<String>? taxableAmount,
      Value<String>? gstAmount,
      Value<String>? cgstAmount,
      Value<String>? sgstAmount,
      Value<String>? igstAmount,
      Value<String>? lineTotal,
      Value<int>? rowid}) {
    return InvoiceItemsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      lineNumber: lineNumber ?? this.lineNumber,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      company: company ?? this.company,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      pricingMode: pricingMode ?? this.pricingMode,
      enteredUnitPrice: enteredUnitPrice ?? this.enteredUnitPrice,
      unitPriceExclTax: unitPriceExclTax ?? this.unitPriceExclTax,
      unitPriceInclTax: unitPriceInclTax ?? this.unitPriceInclTax,
      gstRate: gstRate ?? this.gstRate,
      cgstRate: cgstRate ?? this.cgstRate,
      sgstRate: sgstRate ?? this.sgstRate,
      igstRate: igstRate ?? this.igstRate,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      gstAmount: gstAmount ?? this.gstAmount,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      lineTotal: lineTotal ?? this.lineTotal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (lineNumber.present) {
      map['line_number'] = Variable<int>(lineNumber.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (pricingMode.present) {
      map['pricing_mode'] = Variable<String>(pricingMode.value);
    }
    if (enteredUnitPrice.present) {
      map['entered_unit_price'] = Variable<String>(enteredUnitPrice.value);
    }
    if (unitPriceExclTax.present) {
      map['unit_price_excl_tax'] = Variable<String>(unitPriceExclTax.value);
    }
    if (unitPriceInclTax.present) {
      map['unit_price_incl_tax'] = Variable<String>(unitPriceInclTax.value);
    }
    if (gstRate.present) {
      map['gst_rate'] = Variable<String>(gstRate.value);
    }
    if (cgstRate.present) {
      map['cgst_rate'] = Variable<String>(cgstRate.value);
    }
    if (sgstRate.present) {
      map['sgst_rate'] = Variable<String>(sgstRate.value);
    }
    if (igstRate.present) {
      map['igst_rate'] = Variable<String>(igstRate.value);
    }
    if (discountPercent.present) {
      map['discount_percent'] = Variable<String>(discountPercent.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<String>(discountAmount.value);
    }
    if (taxableAmount.present) {
      map['taxable_amount'] = Variable<String>(taxableAmount.value);
    }
    if (gstAmount.present) {
      map['gst_amount'] = Variable<String>(gstAmount.value);
    }
    if (cgstAmount.present) {
      map['cgst_amount'] = Variable<String>(cgstAmount.value);
    }
    if (sgstAmount.present) {
      map['sgst_amount'] = Variable<String>(sgstAmount.value);
    }
    if (igstAmount.present) {
      map['igst_amount'] = Variable<String>(igstAmount.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<String>(lineTotal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('lineNumber: $lineNumber, ')
          ..write('productName: $productName, ')
          ..write('productCode: $productCode, ')
          ..write('company: $company, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('pricingMode: $pricingMode, ')
          ..write('enteredUnitPrice: $enteredUnitPrice, ')
          ..write('unitPriceExclTax: $unitPriceExclTax, ')
          ..write('unitPriceInclTax: $unitPriceInclTax, ')
          ..write('gstRate: $gstRate, ')
          ..write('cgstRate: $cgstRate, ')
          ..write('sgstRate: $sgstRate, ')
          ..write('igstRate: $igstRate, ')
          ..write('discountPercent: $discountPercent, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxableAmount: $taxableAmount, ')
          ..write('gstAmount: $gstAmount, ')
          ..write('cgstAmount: $cgstAmount, ')
          ..write('sgstAmount: $sgstAmount, ')
          ..write('igstAmount: $igstAmount, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSessionsTable extends LocalSessions
    with TableInfo<$LocalSessionsTable, LocalSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localUserIdMeta =
      const VerificationMeta('localUserId');
  @override
  late final GeneratedColumn<String> localUserId = GeneratedColumn<String>(
      'local_user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES local_users (id)'));
  static const VerificationMeta _sessionTokenHashMeta =
      const VerificationMeta('sessionTokenHash');
  @override
  late final GeneratedColumn<String> sessionTokenHash = GeneratedColumn<String>(
      'session_token_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _refreshTokenHashMeta =
      const VerificationMeta('refreshTokenHash');
  @override
  late final GeneratedColumn<String> refreshTokenHash = GeneratedColumn<String>(
      'refresh_token_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<String> expiresAt = GeneratedColumn<String>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        localUserId,
        sessionTokenHash,
        refreshTokenHash,
        createdAt,
        expiresAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_user_id')) {
      context.handle(
          _localUserIdMeta,
          localUserId.isAcceptableOrUnknown(
              data['local_user_id']!, _localUserIdMeta));
    } else if (isInserting) {
      context.missing(_localUserIdMeta);
    }
    if (data.containsKey('session_token_hash')) {
      context.handle(
          _sessionTokenHashMeta,
          sessionTokenHash.isAcceptableOrUnknown(
              data['session_token_hash']!, _sessionTokenHashMeta));
    } else if (isInserting) {
      context.missing(_sessionTokenHashMeta);
    }
    if (data.containsKey('refresh_token_hash')) {
      context.handle(
          _refreshTokenHashMeta,
          refreshTokenHash.isAcceptableOrUnknown(
              data['refresh_token_hash']!, _refreshTokenHashMeta));
    } else if (isInserting) {
      context.missing(_refreshTokenHashMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      localUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_user_id'])!,
      sessionTokenHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_token_hash'])!,
      refreshTokenHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}refresh_token_hash'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expires_at']),
    );
  }

  @override
  $LocalSessionsTable createAlias(String alias) {
    return $LocalSessionsTable(attachedDatabase, alias);
  }
}

class LocalSession extends DataClass implements Insertable<LocalSession> {
  final String id;
  final String localUserId;
  final String sessionTokenHash;
  final String refreshTokenHash;
  final String createdAt;
  final String? expiresAt;
  const LocalSession(
      {required this.id,
      required this.localUserId,
      required this.sessionTokenHash,
      required this.refreshTokenHash,
      required this.createdAt,
      this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_user_id'] = Variable<String>(localUserId);
    map['session_token_hash'] = Variable<String>(sessionTokenHash);
    map['refresh_token_hash'] = Variable<String>(refreshTokenHash);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<String>(expiresAt);
    }
    return map;
  }

  LocalSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalSessionsCompanion(
      id: Value(id),
      localUserId: Value(localUserId),
      sessionTokenHash: Value(sessionTokenHash),
      refreshTokenHash: Value(refreshTokenHash),
      createdAt: Value(createdAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
    );
  }

  factory LocalSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSession(
      id: serializer.fromJson<String>(json['id']),
      localUserId: serializer.fromJson<String>(json['localUserId']),
      sessionTokenHash: serializer.fromJson<String>(json['sessionTokenHash']),
      refreshTokenHash: serializer.fromJson<String>(json['refreshTokenHash']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      expiresAt: serializer.fromJson<String?>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localUserId': serializer.toJson<String>(localUserId),
      'sessionTokenHash': serializer.toJson<String>(sessionTokenHash),
      'refreshTokenHash': serializer.toJson<String>(refreshTokenHash),
      'createdAt': serializer.toJson<String>(createdAt),
      'expiresAt': serializer.toJson<String?>(expiresAt),
    };
  }

  LocalSession copyWith(
          {String? id,
          String? localUserId,
          String? sessionTokenHash,
          String? refreshTokenHash,
          String? createdAt,
          Value<String?> expiresAt = const Value.absent()}) =>
      LocalSession(
        id: id ?? this.id,
        localUserId: localUserId ?? this.localUserId,
        sessionTokenHash: sessionTokenHash ?? this.sessionTokenHash,
        refreshTokenHash: refreshTokenHash ?? this.refreshTokenHash,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
      );
  LocalSession copyWithCompanion(LocalSessionsCompanion data) {
    return LocalSession(
      id: data.id.present ? data.id.value : this.id,
      localUserId:
          data.localUserId.present ? data.localUserId.value : this.localUserId,
      sessionTokenHash: data.sessionTokenHash.present
          ? data.sessionTokenHash.value
          : this.sessionTokenHash,
      refreshTokenHash: data.refreshTokenHash.present
          ? data.refreshTokenHash.value
          : this.refreshTokenHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSession(')
          ..write('id: $id, ')
          ..write('localUserId: $localUserId, ')
          ..write('sessionTokenHash: $sessionTokenHash, ')
          ..write('refreshTokenHash: $refreshTokenHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, localUserId, sessionTokenHash,
      refreshTokenHash, createdAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSession &&
          other.id == this.id &&
          other.localUserId == this.localUserId &&
          other.sessionTokenHash == this.sessionTokenHash &&
          other.refreshTokenHash == this.refreshTokenHash &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class LocalSessionsCompanion extends UpdateCompanion<LocalSession> {
  final Value<String> id;
  final Value<String> localUserId;
  final Value<String> sessionTokenHash;
  final Value<String> refreshTokenHash;
  final Value<String> createdAt;
  final Value<String?> expiresAt;
  final Value<int> rowid;
  const LocalSessionsCompanion({
    this.id = const Value.absent(),
    this.localUserId = const Value.absent(),
    this.sessionTokenHash = const Value.absent(),
    this.refreshTokenHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSessionsCompanion.insert({
    required String id,
    required String localUserId,
    required String sessionTokenHash,
    required String refreshTokenHash,
    required String createdAt,
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        localUserId = Value(localUserId),
        sessionTokenHash = Value(sessionTokenHash),
        refreshTokenHash = Value(refreshTokenHash),
        createdAt = Value(createdAt);
  static Insertable<LocalSession> custom({
    Expression<String>? id,
    Expression<String>? localUserId,
    Expression<String>? sessionTokenHash,
    Expression<String>? refreshTokenHash,
    Expression<String>? createdAt,
    Expression<String>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localUserId != null) 'local_user_id': localUserId,
      if (sessionTokenHash != null) 'session_token_hash': sessionTokenHash,
      if (refreshTokenHash != null) 'refresh_token_hash': refreshTokenHash,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? localUserId,
      Value<String>? sessionTokenHash,
      Value<String>? refreshTokenHash,
      Value<String>? createdAt,
      Value<String?>? expiresAt,
      Value<int>? rowid}) {
    return LocalSessionsCompanion(
      id: id ?? this.id,
      localUserId: localUserId ?? this.localUserId,
      sessionTokenHash: sessionTokenHash ?? this.sessionTokenHash,
      refreshTokenHash: refreshTokenHash ?? this.refreshTokenHash,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localUserId.present) {
      map['local_user_id'] = Variable<String>(localUserId.value);
    }
    if (sessionTokenHash.present) {
      map['session_token_hash'] = Variable<String>(sessionTokenHash.value);
    }
    if (refreshTokenHash.present) {
      map['refresh_token_hash'] = Variable<String>(refreshTokenHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<String>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSessionsCompanion(')
          ..write('id: $id, ')
          ..write('localUserId: $localUserId, ')
          ..write('sessionTokenHash: $sessionTokenHash, ')
          ..write('refreshTokenHash: $refreshTokenHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BackupEventsTable extends BackupEvents
    with TableInfo<$BackupEventsTable, BackupEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, eventType, status, filePath, message, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_events';
  @override
  VerificationContext validateIntegrity(Insertable<BackupEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BackupEventsTable createAlias(String alias) {
    return $BackupEventsTable(attachedDatabase, alias);
  }
}

class BackupEvent extends DataClass implements Insertable<BackupEvent> {
  final String id;
  final String eventType;
  final String status;
  final String? filePath;
  final String? message;
  final String createdAt;
  const BackupEvent(
      {required this.id,
      required this.eventType,
      required this.status,
      this.filePath,
      this.message,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_type'] = Variable<String>(eventType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  BackupEventsCompanion toCompanion(bool nullToAbsent) {
    return BackupEventsCompanion(
      id: Value(id),
      eventType: Value(eventType),
      status: Value(status),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      createdAt: Value(createdAt),
    );
  }

  factory BackupEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupEvent(
      id: serializer.fromJson<String>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      status: serializer.fromJson<String>(json['status']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      message: serializer.fromJson<String?>(json['message']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventType': serializer.toJson<String>(eventType),
      'status': serializer.toJson<String>(status),
      'filePath': serializer.toJson<String?>(filePath),
      'message': serializer.toJson<String?>(message),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  BackupEvent copyWith(
          {String? id,
          String? eventType,
          String? status,
          Value<String?> filePath = const Value.absent(),
          Value<String?> message = const Value.absent(),
          String? createdAt}) =>
      BackupEvent(
        id: id ?? this.id,
        eventType: eventType ?? this.eventType,
        status: status ?? this.status,
        filePath: filePath.present ? filePath.value : this.filePath,
        message: message.present ? message.value : this.message,
        createdAt: createdAt ?? this.createdAt,
      );
  BackupEvent copyWithCompanion(BackupEventsCompanion data) {
    return BackupEvent(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      status: data.status.present ? data.status.value : this.status,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupEvent(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, eventType, status, filePath, message, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupEvent &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.status == this.status &&
          other.filePath == this.filePath &&
          other.message == this.message &&
          other.createdAt == this.createdAt);
}

class BackupEventsCompanion extends UpdateCompanion<BackupEvent> {
  final Value<String> id;
  final Value<String> eventType;
  final Value<String> status;
  final Value<String?> filePath;
  final Value<String?> message;
  final Value<String> createdAt;
  final Value<int> rowid;
  const BackupEventsCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.status = const Value.absent(),
    this.filePath = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BackupEventsCompanion.insert({
    required String id,
    required String eventType,
    required String status,
    this.filePath = const Value.absent(),
    this.message = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        eventType = Value(eventType),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<BackupEvent> custom({
    Expression<String>? id,
    Expression<String>? eventType,
    Expression<String>? status,
    Expression<String>? filePath,
    Expression<String>? message,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (status != null) 'status': status,
      if (filePath != null) 'file_path': filePath,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BackupEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? eventType,
      Value<String>? status,
      Value<String?>? filePath,
      Value<String?>? message,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return BackupEventsCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BackupSettingsTable extends BackupSettings
    with TableInfo<$BackupSettingsTable, BackupSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _backupDirectoryMeta =
      const VerificationMeta('backupDirectory');
  @override
  late final GeneratedColumn<String> backupDirectory = GeneratedColumn<String>(
      'backup_directory', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _automaticBackupsEnabledMeta =
      const VerificationMeta('automaticBackupsEnabled');
  @override
  late final GeneratedColumn<bool> automaticBackupsEnabled =
      GeneratedColumn<bool>('automatic_backups_enabled', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("automatic_backups_enabled" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _lastBackupAtMeta =
      const VerificationMeta('lastBackupAt');
  @override
  late final GeneratedColumn<String> lastBackupAt = GeneratedColumn<String>(
      'last_backup_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, backupDirectory, automaticBackupsEnabled, lastBackupAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_settings';
  @override
  VerificationContext validateIntegrity(Insertable<BackupSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('backup_directory')) {
      context.handle(
          _backupDirectoryMeta,
          backupDirectory.isAcceptableOrUnknown(
              data['backup_directory']!, _backupDirectoryMeta));
    }
    if (data.containsKey('automatic_backups_enabled')) {
      context.handle(
          _automaticBackupsEnabledMeta,
          automaticBackupsEnabled.isAcceptableOrUnknown(
              data['automatic_backups_enabled']!,
              _automaticBackupsEnabledMeta));
    }
    if (data.containsKey('last_backup_at')) {
      context.handle(
          _lastBackupAtMeta,
          lastBackupAt.isAcceptableOrUnknown(
              data['last_backup_at']!, _lastBackupAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      backupDirectory: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}backup_directory']),
      automaticBackupsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}automatic_backups_enabled'])!,
      lastBackupAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_backup_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BackupSettingsTable createAlias(String alias) {
    return $BackupSettingsTable(attachedDatabase, alias);
  }
}

class BackupSetting extends DataClass implements Insertable<BackupSetting> {
  final String id;
  final String? backupDirectory;
  final bool automaticBackupsEnabled;
  final String? lastBackupAt;
  final String updatedAt;
  const BackupSetting(
      {required this.id,
      this.backupDirectory,
      required this.automaticBackupsEnabled,
      this.lastBackupAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || backupDirectory != null) {
      map['backup_directory'] = Variable<String>(backupDirectory);
    }
    map['automatic_backups_enabled'] = Variable<bool>(automaticBackupsEnabled);
    if (!nullToAbsent || lastBackupAt != null) {
      map['last_backup_at'] = Variable<String>(lastBackupAt);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  BackupSettingsCompanion toCompanion(bool nullToAbsent) {
    return BackupSettingsCompanion(
      id: Value(id),
      backupDirectory: backupDirectory == null && nullToAbsent
          ? const Value.absent()
          : Value(backupDirectory),
      automaticBackupsEnabled: Value(automaticBackupsEnabled),
      lastBackupAt: lastBackupAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BackupSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupSetting(
      id: serializer.fromJson<String>(json['id']),
      backupDirectory: serializer.fromJson<String?>(json['backupDirectory']),
      automaticBackupsEnabled:
          serializer.fromJson<bool>(json['automaticBackupsEnabled']),
      lastBackupAt: serializer.fromJson<String?>(json['lastBackupAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'backupDirectory': serializer.toJson<String?>(backupDirectory),
      'automaticBackupsEnabled':
          serializer.toJson<bool>(automaticBackupsEnabled),
      'lastBackupAt': serializer.toJson<String?>(lastBackupAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  BackupSetting copyWith(
          {String? id,
          Value<String?> backupDirectory = const Value.absent(),
          bool? automaticBackupsEnabled,
          Value<String?> lastBackupAt = const Value.absent(),
          String? updatedAt}) =>
      BackupSetting(
        id: id ?? this.id,
        backupDirectory: backupDirectory.present
            ? backupDirectory.value
            : this.backupDirectory,
        automaticBackupsEnabled:
            automaticBackupsEnabled ?? this.automaticBackupsEnabled,
        lastBackupAt:
            lastBackupAt.present ? lastBackupAt.value : this.lastBackupAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BackupSetting copyWithCompanion(BackupSettingsCompanion data) {
    return BackupSetting(
      id: data.id.present ? data.id.value : this.id,
      backupDirectory: data.backupDirectory.present
          ? data.backupDirectory.value
          : this.backupDirectory,
      automaticBackupsEnabled: data.automaticBackupsEnabled.present
          ? data.automaticBackupsEnabled.value
          : this.automaticBackupsEnabled,
      lastBackupAt: data.lastBackupAt.present
          ? data.lastBackupAt.value
          : this.lastBackupAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupSetting(')
          ..write('id: $id, ')
          ..write('backupDirectory: $backupDirectory, ')
          ..write('automaticBackupsEnabled: $automaticBackupsEnabled, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, backupDirectory, automaticBackupsEnabled, lastBackupAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupSetting &&
          other.id == this.id &&
          other.backupDirectory == this.backupDirectory &&
          other.automaticBackupsEnabled == this.automaticBackupsEnabled &&
          other.lastBackupAt == this.lastBackupAt &&
          other.updatedAt == this.updatedAt);
}

class BackupSettingsCompanion extends UpdateCompanion<BackupSetting> {
  final Value<String> id;
  final Value<String?> backupDirectory;
  final Value<bool> automaticBackupsEnabled;
  final Value<String?> lastBackupAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const BackupSettingsCompanion({
    this.id = const Value.absent(),
    this.backupDirectory = const Value.absent(),
    this.automaticBackupsEnabled = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BackupSettingsCompanion.insert({
    required String id,
    this.backupDirectory = const Value.absent(),
    this.automaticBackupsEnabled = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        updatedAt = Value(updatedAt);
  static Insertable<BackupSetting> custom({
    Expression<String>? id,
    Expression<String>? backupDirectory,
    Expression<bool>? automaticBackupsEnabled,
    Expression<String>? lastBackupAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (backupDirectory != null) 'backup_directory': backupDirectory,
      if (automaticBackupsEnabled != null)
        'automatic_backups_enabled': automaticBackupsEnabled,
      if (lastBackupAt != null) 'last_backup_at': lastBackupAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BackupSettingsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? backupDirectory,
      Value<bool>? automaticBackupsEnabled,
      Value<String?>? lastBackupAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return BackupSettingsCompanion(
      id: id ?? this.id,
      backupDirectory: backupDirectory ?? this.backupDirectory,
      automaticBackupsEnabled:
          automaticBackupsEnabled ?? this.automaticBackupsEnabled,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (backupDirectory.present) {
      map['backup_directory'] = Variable<String>(backupDirectory.value);
    }
    if (automaticBackupsEnabled.present) {
      map['automatic_backups_enabled'] =
          Variable<bool>(automaticBackupsEnabled.value);
    }
    if (lastBackupAt.present) {
      map['last_backup_at'] = Variable<String>(lastBackupAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupSettingsCompanion(')
          ..write('id: $id, ')
          ..write('backupDirectory: $backupDirectory, ')
          ..write('automaticBackupsEnabled: $automaticBackupsEnabled, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $LocalUsersTable localUsers = $LocalUsersTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $SellersTable sellers = $SellersTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $StockMovementsTable stockMovements = $StockMovementsTable(this);
  late final $SellerTransactionsTable sellerTransactions =
      $SellerTransactionsTable(this);
  late final $CompanyProfilesTable companyProfiles =
      $CompanyProfilesTable(this);
  late final $InvoiceItemsTable invoiceItems = $InvoiceItemsTable(this);
  late final $LocalSessionsTable localSessions = $LocalSessionsTable(this);
  late final $BackupEventsTable backupEvents = $BackupEventsTable(this);
  late final $BackupSettingsTable backupSettings = $BackupSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localUsers,
        products,
        sellers,
        invoices,
        stockMovements,
        sellerTransactions,
        companyProfiles,
        invoiceItems,
        localSessions,
        backupEvents,
        backupSettings
      ];
}

typedef $$LocalUsersTableCreateCompanionBuilder = LocalUsersCompanion Function({
  required String id,
  required String username,
  required String passwordHash,
  Value<String?> displayName,
  Value<bool> isActive,
  required String salt,
  required int passwordHashVersion,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$LocalUsersTableUpdateCompanionBuilder = LocalUsersCompanion Function({
  Value<String> id,
  Value<String> username,
  Value<String> passwordHash,
  Value<String?> displayName,
  Value<bool> isActive,
  Value<String> salt,
  Value<int> passwordHashVersion,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$LocalUsersTableReferences
    extends BaseReferences<_$LocalDatabase, $LocalUsersTable, LocalUser> {
  $$LocalUsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InvoicesTable, List<Invoice>>
      _createdInvoicesTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.invoices,
              aliasName: $_aliasNameGenerator(
                  db.localUsers.id, db.invoices.createdByUserId));

  $$InvoicesTableProcessedTableManager get createdInvoices {
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices).filter(
        (f) => f.createdByUserId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_createdInvoicesTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InvoicesTable, List<Invoice>>
      _canceledInvoicesTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.invoices,
              aliasName: $_aliasNameGenerator(
                  db.localUsers.id, db.invoices.canceledByUserId));

  $$InvoicesTableProcessedTableManager get canceledInvoices {
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices).filter(
        (f) => f.canceledByUserId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_canceledInvoicesTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
      _stockMovementsRefsTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockMovements,
              aliasName: $_aliasNameGenerator(
                  db.localUsers.id, db.stockMovements.createdByUserId));

  $$StockMovementsTableProcessedTableManager get stockMovementsRefs {
    final manager = $$StockMovementsTableTableManager($_db, $_db.stockMovements)
        .filter(
            (f) => f.createdByUserId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SellerTransactionsTable, List<SellerTransaction>>
      _sellerTransactionsRefsTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.sellerTransactions,
              aliasName: $_aliasNameGenerator(
                  db.localUsers.id, db.sellerTransactions.createdByUserId));

  $$SellerTransactionsTableProcessedTableManager get sellerTransactionsRefs {
    final manager = $$SellerTransactionsTableTableManager(
            $_db, $_db.sellerTransactions)
        .filter(
            (f) => f.createdByUserId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_sellerTransactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LocalSessionsTable, List<LocalSession>>
      _localSessionsRefsTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.localSessions,
              aliasName: $_aliasNameGenerator(
                  db.localUsers.id, db.localSessions.localUserId));

  $$LocalSessionsTableProcessedTableManager get localSessionsRefs {
    final manager = $$LocalSessionsTableTableManager($_db, $_db.localSessions)
        .filter((f) => f.localUserId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_localSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LocalUsersTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalUsersTable> {
  $$LocalUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get salt => $composableBuilder(
      column: $table.salt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get passwordHashVersion => $composableBuilder(
      column: $table.passwordHashVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> createdInvoices(
      Expression<bool> Function($$InvoicesTableFilterComposer f) f) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.createdByUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> canceledInvoices(
      Expression<bool> Function($$InvoicesTableFilterComposer f) f) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.canceledByUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stockMovementsRefs(
      Expression<bool> Function($$StockMovementsTableFilterComposer f) f) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.createdByUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableFilterComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> sellerTransactionsRefs(
      Expression<bool> Function($$SellerTransactionsTableFilterComposer f) f) {
    final $$SellerTransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sellerTransactions,
        getReferencedColumn: (t) => t.createdByUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SellerTransactionsTableFilterComposer(
              $db: $db,
              $table: $db.sellerTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> localSessionsRefs(
      Expression<bool> Function($$LocalSessionsTableFilterComposer f) f) {
    final $$LocalSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localSessions,
        getReferencedColumn: (t) => t.localUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalSessionsTableFilterComposer(
              $db: $db,
              $table: $db.localSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalUsersTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalUsersTable> {
  $$LocalUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get salt => $composableBuilder(
      column: $table.salt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get passwordHashVersion => $composableBuilder(
      column: $table.passwordHashVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalUsersTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalUsersTable> {
  $$LocalUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get salt =>
      $composableBuilder(column: $table.salt, builder: (column) => column);

  GeneratedColumn<int> get passwordHashVersion => $composableBuilder(
      column: $table.passwordHashVersion, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> createdInvoices<T extends Object>(
      Expression<T> Function($$InvoicesTableAnnotationComposer a) f) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.createdByUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> canceledInvoices<T extends Object>(
      Expression<T> Function($$InvoicesTableAnnotationComposer a) f) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.canceledByUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> stockMovementsRefs<T extends Object>(
      Expression<T> Function($$StockMovementsTableAnnotationComposer a) f) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.createdByUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> sellerTransactionsRefs<T extends Object>(
      Expression<T> Function($$SellerTransactionsTableAnnotationComposer a) f) {
    final $$SellerTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.sellerTransactions,
            getReferencedColumn: (t) => t.createdByUserId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SellerTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.sellerTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> localSessionsRefs<T extends Object>(
      Expression<T> Function($$LocalSessionsTableAnnotationComposer a) f) {
    final $$LocalSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.localSessions,
        getReferencedColumn: (t) => t.localUserId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.localSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalUsersTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalUsersTable,
    LocalUser,
    $$LocalUsersTableFilterComposer,
    $$LocalUsersTableOrderingComposer,
    $$LocalUsersTableAnnotationComposer,
    $$LocalUsersTableCreateCompanionBuilder,
    $$LocalUsersTableUpdateCompanionBuilder,
    (LocalUser, $$LocalUsersTableReferences),
    LocalUser,
    PrefetchHooks Function(
        {bool createdInvoices,
        bool canceledInvoices,
        bool stockMovementsRefs,
        bool sellerTransactionsRefs,
        bool localSessionsRefs})> {
  $$LocalUsersTableTableManager(_$LocalDatabase db, $LocalUsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> salt = const Value.absent(),
            Value<int> passwordHashVersion = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalUsersCompanion(
            id: id,
            username: username,
            passwordHash: passwordHash,
            displayName: displayName,
            isActive: isActive,
            salt: salt,
            passwordHashVersion: passwordHashVersion,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String username,
            required String passwordHash,
            Value<String?> displayName = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required String salt,
            required int passwordHashVersion,
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalUsersCompanion.insert(
            id: id,
            username: username,
            passwordHash: passwordHash,
            displayName: displayName,
            isActive: isActive,
            salt: salt,
            passwordHashVersion: passwordHashVersion,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LocalUsersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {createdInvoices = false,
              canceledInvoices = false,
              stockMovementsRefs = false,
              sellerTransactionsRefs = false,
              localSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (createdInvoices) db.invoices,
                if (canceledInvoices) db.invoices,
                if (stockMovementsRefs) db.stockMovements,
                if (sellerTransactionsRefs) db.sellerTransactions,
                if (localSessionsRefs) db.localSessions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (createdInvoices)
                    await $_getPrefetchedData<LocalUser, $LocalUsersTable,
                            Invoice>(
                        currentTable: table,
                        referencedTable: $$LocalUsersTableReferences
                            ._createdInvoicesTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalUsersTableReferences(db, table, p0)
                                .createdInvoices,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.createdByUserId == item.id),
                        typedResults: items),
                  if (canceledInvoices)
                    await $_getPrefetchedData<LocalUser, $LocalUsersTable,
                            Invoice>(
                        currentTable: table,
                        referencedTable: $$LocalUsersTableReferences
                            ._canceledInvoicesTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalUsersTableReferences(db, table, p0)
                                .canceledInvoices,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.canceledByUserId == item.id),
                        typedResults: items),
                  if (stockMovementsRefs)
                    await $_getPrefetchedData<LocalUser, $LocalUsersTable,
                            StockMovement>(
                        currentTable: table,
                        referencedTable: $$LocalUsersTableReferences
                            ._stockMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalUsersTableReferences(db, table, p0)
                                .stockMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.createdByUserId == item.id),
                        typedResults: items),
                  if (sellerTransactionsRefs)
                    await $_getPrefetchedData<LocalUser, $LocalUsersTable,
                            SellerTransaction>(
                        currentTable: table,
                        referencedTable: $$LocalUsersTableReferences
                            ._sellerTransactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalUsersTableReferences(db, table, p0)
                                .sellerTransactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.createdByUserId == item.id),
                        typedResults: items),
                  if (localSessionsRefs)
                    await $_getPrefetchedData<LocalUser, $LocalUsersTable,
                            LocalSession>(
                        currentTable: table,
                        referencedTable: $$LocalUsersTableReferences
                            ._localSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalUsersTableReferences(db, table, p0)
                                .localSessionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.localUserId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LocalUsersTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $LocalUsersTable,
    LocalUser,
    $$LocalUsersTableFilterComposer,
    $$LocalUsersTableOrderingComposer,
    $$LocalUsersTableAnnotationComposer,
    $$LocalUsersTableCreateCompanionBuilder,
    $$LocalUsersTableUpdateCompanionBuilder,
    (LocalUser, $$LocalUsersTableReferences),
    LocalUser,
    PrefetchHooks Function(
        {bool createdInvoices,
        bool canceledInvoices,
        bool stockMovementsRefs,
        bool sellerTransactionsRefs,
        bool localSessionsRefs})>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String company,
  required String category,
  required String itemName,
  required String itemCode,
  Value<String?> buyingPriceExclTax,
  Value<String?> buyingGstRate,
  required String defaultSellingPriceExclTax,
  required String defaultGstRate,
  required String quantityOnHand,
  required String lowStockThreshold,
  Value<bool> isActive,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> company,
  Value<String> category,
  Value<String> itemName,
  Value<String> itemCode,
  Value<String?> buyingPriceExclTax,
  Value<String?> buyingGstRate,
  Value<String> defaultSellingPriceExclTax,
  Value<String> defaultGstRate,
  Value<String> quantityOnHand,
  Value<String> lowStockThreshold,
  Value<bool> isActive,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$LocalDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
      _stockMovementsRefsTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockMovements,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.stockMovements.productId));

  $$StockMovementsTableProcessedTableManager get stockMovementsRefs {
    final manager = $$StockMovementsTableTableManager($_db, $_db.stockMovements)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InvoiceItemsTable, List<InvoiceItem>>
      _invoiceItemsRefsTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.invoiceItems,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.invoiceItems.productId));

  $$InvoiceItemsTableProcessedTableManager get invoiceItemsRefs {
    final manager = $$InvoiceItemsTableTableManager($_db, $_db.invoiceItems)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$LocalDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemName => $composableBuilder(
      column: $table.itemName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemCode => $composableBuilder(
      column: $table.itemCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get buyingPriceExclTax => $composableBuilder(
      column: $table.buyingPriceExclTax,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get buyingGstRate => $composableBuilder(
      column: $table.buyingGstRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultSellingPriceExclTax => $composableBuilder(
      column: $table.defaultSellingPriceExclTax,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultGstRate => $composableBuilder(
      column: $table.defaultGstRate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quantityOnHand => $composableBuilder(
      column: $table.quantityOnHand,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lowStockThreshold => $composableBuilder(
      column: $table.lowStockThreshold,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> stockMovementsRefs(
      Expression<bool> Function($$StockMovementsTableFilterComposer f) f) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableFilterComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> invoiceItemsRefs(
      Expression<bool> Function($$InvoiceItemsTableFilterComposer f) f) {
    final $$InvoiceItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoiceItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoiceItemsTableFilterComposer(
              $db: $db,
              $table: $db.invoiceItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$LocalDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemName => $composableBuilder(
      column: $table.itemName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemCode => $composableBuilder(
      column: $table.itemCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get buyingPriceExclTax => $composableBuilder(
      column: $table.buyingPriceExclTax,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get buyingGstRate => $composableBuilder(
      column: $table.buyingGstRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultSellingPriceExclTax => $composableBuilder(
      column: $table.defaultSellingPriceExclTax,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultGstRate => $composableBuilder(
      column: $table.defaultGstRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quantityOnHand => $composableBuilder(
      column: $table.quantityOnHand,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lowStockThreshold => $composableBuilder(
      column: $table.lowStockThreshold,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get itemCode =>
      $composableBuilder(column: $table.itemCode, builder: (column) => column);

  GeneratedColumn<String> get buyingPriceExclTax => $composableBuilder(
      column: $table.buyingPriceExclTax, builder: (column) => column);

  GeneratedColumn<String> get buyingGstRate => $composableBuilder(
      column: $table.buyingGstRate, builder: (column) => column);

  GeneratedColumn<String> get defaultSellingPriceExclTax => $composableBuilder(
      column: $table.defaultSellingPriceExclTax, builder: (column) => column);

  GeneratedColumn<String> get defaultGstRate => $composableBuilder(
      column: $table.defaultGstRate, builder: (column) => column);

  GeneratedColumn<String> get quantityOnHand => $composableBuilder(
      column: $table.quantityOnHand, builder: (column) => column);

  GeneratedColumn<String> get lowStockThreshold => $composableBuilder(
      column: $table.lowStockThreshold, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> stockMovementsRefs<T extends Object>(
      Expression<T> Function($$StockMovementsTableAnnotationComposer a) f) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> invoiceItemsRefs<T extends Object>(
      Expression<T> Function($$InvoiceItemsTableAnnotationComposer a) f) {
    final $$InvoiceItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoiceItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoiceItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.invoiceItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, $$ProductsTableReferences),
    Product,
    PrefetchHooks Function({bool stockMovementsRefs, bool invoiceItemsRefs})> {
  $$ProductsTableTableManager(_$LocalDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> company = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> itemName = const Value.absent(),
            Value<String> itemCode = const Value.absent(),
            Value<String?> buyingPriceExclTax = const Value.absent(),
            Value<String?> buyingGstRate = const Value.absent(),
            Value<String> defaultSellingPriceExclTax = const Value.absent(),
            Value<String> defaultGstRate = const Value.absent(),
            Value<String> quantityOnHand = const Value.absent(),
            Value<String> lowStockThreshold = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            company: company,
            category: category,
            itemName: itemName,
            itemCode: itemCode,
            buyingPriceExclTax: buyingPriceExclTax,
            buyingGstRate: buyingGstRate,
            defaultSellingPriceExclTax: defaultSellingPriceExclTax,
            defaultGstRate: defaultGstRate,
            quantityOnHand: quantityOnHand,
            lowStockThreshold: lowStockThreshold,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String company,
            required String category,
            required String itemName,
            required String itemCode,
            Value<String?> buyingPriceExclTax = const Value.absent(),
            Value<String?> buyingGstRate = const Value.absent(),
            required String defaultSellingPriceExclTax,
            required String defaultGstRate,
            required String quantityOnHand,
            required String lowStockThreshold,
            Value<bool> isActive = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            company: company,
            category: category,
            itemName: itemName,
            itemCode: itemCode,
            buyingPriceExclTax: buyingPriceExclTax,
            buyingGstRate: buyingGstRate,
            defaultSellingPriceExclTax: defaultSellingPriceExclTax,
            defaultGstRate: defaultGstRate,
            quantityOnHand: quantityOnHand,
            lowStockThreshold: lowStockThreshold,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProductsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {stockMovementsRefs = false, invoiceItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (stockMovementsRefs) db.stockMovements,
                if (invoiceItemsRefs) db.invoiceItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stockMovementsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            StockMovement>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._stockMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .stockMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (invoiceItemsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            InvoiceItem>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._invoiceItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .invoiceItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, $$ProductsTableReferences),
    Product,
    PrefetchHooks Function({bool stockMovementsRefs, bool invoiceItemsRefs})>;
typedef $$SellersTableCreateCompanionBuilder = SellersCompanion Function({
  required String id,
  required String name,
  required String address,
  Value<String?> state,
  Value<String?> stateCode,
  Value<String?> phone,
  Value<String?> gstin,
  Value<bool> isActive,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$SellersTableUpdateCompanionBuilder = SellersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> address,
  Value<String?> state,
  Value<String?> stateCode,
  Value<String?> phone,
  Value<String?> gstin,
  Value<bool> isActive,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$SellersTableReferences
    extends BaseReferences<_$LocalDatabase, $SellersTable, Seller> {
  $$SellersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InvoicesTable, List<Invoice>> _invoicesRefsTable(
          _$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(db.invoices,
          aliasName: $_aliasNameGenerator(db.sellers.id, db.invoices.sellerId));

  $$InvoicesTableProcessedTableManager get invoicesRefs {
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.sellerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoicesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SellerTransactionsTable, List<SellerTransaction>>
      _sellerTransactionsRefsTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.sellerTransactions,
              aliasName: $_aliasNameGenerator(
                  db.sellers.id, db.sellerTransactions.sellerId));

  $$SellerTransactionsTableProcessedTableManager get sellerTransactionsRefs {
    final manager = $$SellerTransactionsTableTableManager(
            $_db, $_db.sellerTransactions)
        .filter((f) => f.sellerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_sellerTransactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SellersTableFilterComposer
    extends Composer<_$LocalDatabase, $SellersTable> {
  $$SellersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stateCode => $composableBuilder(
      column: $table.stateCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gstin => $composableBuilder(
      column: $table.gstin, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> invoicesRefs(
      Expression<bool> Function($$InvoicesTableFilterComposer f) f) {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.sellerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> sellerTransactionsRefs(
      Expression<bool> Function($$SellerTransactionsTableFilterComposer f) f) {
    final $$SellerTransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sellerTransactions,
        getReferencedColumn: (t) => t.sellerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SellerTransactionsTableFilterComposer(
              $db: $db,
              $table: $db.sellerTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SellersTableOrderingComposer
    extends Composer<_$LocalDatabase, $SellersTable> {
  $$SellersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stateCode => $composableBuilder(
      column: $table.stateCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gstin => $composableBuilder(
      column: $table.gstin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SellersTableAnnotationComposer
    extends Composer<_$LocalDatabase, $SellersTable> {
  $$SellersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get stateCode =>
      $composableBuilder(column: $table.stateCode, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get gstin =>
      $composableBuilder(column: $table.gstin, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> invoicesRefs<T extends Object>(
      Expression<T> Function($$InvoicesTableAnnotationComposer a) f) {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.sellerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> sellerTransactionsRefs<T extends Object>(
      Expression<T> Function($$SellerTransactionsTableAnnotationComposer a) f) {
    final $$SellerTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.sellerTransactions,
            getReferencedColumn: (t) => t.sellerId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SellerTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.sellerTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SellersTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $SellersTable,
    Seller,
    $$SellersTableFilterComposer,
    $$SellersTableOrderingComposer,
    $$SellersTableAnnotationComposer,
    $$SellersTableCreateCompanionBuilder,
    $$SellersTableUpdateCompanionBuilder,
    (Seller, $$SellersTableReferences),
    Seller,
    PrefetchHooks Function({bool invoicesRefs, bool sellerTransactionsRefs})> {
  $$SellersTableTableManager(_$LocalDatabase db, $SellersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SellersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SellersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SellersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<String?> state = const Value.absent(),
            Value<String?> stateCode = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> gstin = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SellersCompanion(
            id: id,
            name: name,
            address: address,
            state: state,
            stateCode: stateCode,
            phone: phone,
            gstin: gstin,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String address,
            Value<String?> state = const Value.absent(),
            Value<String?> stateCode = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> gstin = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SellersCompanion.insert(
            id: id,
            name: name,
            address: address,
            state: state,
            stateCode: stateCode,
            phone: phone,
            gstin: gstin,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SellersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {invoicesRefs = false, sellerTransactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (invoicesRefs) db.invoices,
                if (sellerTransactionsRefs) db.sellerTransactions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (invoicesRefs)
                    await $_getPrefetchedData<Seller, $SellersTable, Invoice>(
                        currentTable: table,
                        referencedTable:
                            $$SellersTableReferences._invoicesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SellersTableReferences(db, table, p0)
                                .invoicesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.sellerId == item.id),
                        typedResults: items),
                  if (sellerTransactionsRefs)
                    await $_getPrefetchedData<Seller, $SellersTable,
                            SellerTransaction>(
                        currentTable: table,
                        referencedTable: $$SellersTableReferences
                            ._sellerTransactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SellersTableReferences(db, table, p0)
                                .sellerTransactionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.sellerId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SellersTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $SellersTable,
    Seller,
    $$SellersTableFilterComposer,
    $$SellersTableOrderingComposer,
    $$SellersTableAnnotationComposer,
    $$SellersTableCreateCompanionBuilder,
    $$SellersTableUpdateCompanionBuilder,
    (Seller, $$SellersTableReferences),
    Seller,
    PrefetchHooks Function({bool invoicesRefs, bool sellerTransactionsRefs})>;
typedef $$InvoicesTableCreateCompanionBuilder = InvoicesCompanion Function({
  required String id,
  required String requestId,
  required String requestHash,
  required int invoiceNumber,
  required String sellerId,
  required String sellerName,
  required String sellerAddress,
  Value<String?> sellerState,
  Value<String?> sellerStateCode,
  Value<String?> sellerPhone,
  Value<String?> sellerGstin,
  required String placeOfSupplyState,
  required String placeOfSupplyStateCode,
  required String companyName,
  required String companyAddress,
  required String companyCity,
  required String companyState,
  required String companyStateCode,
  Value<String?> companyGstin,
  Value<String?> companyPhone,
  Value<String?> companyEmail,
  Value<String?> companyBankName,
  Value<String?> companyBankAccount,
  Value<String?> companyBankIfsc,
  Value<String?> companyBankBranch,
  Value<String?> companyJurisdiction,
  required String invoiceDate,
  required String taxRegime,
  required String status,
  required String paymentMode,
  required String subtotal,
  required String discountTotal,
  required String taxableTotal,
  required String gstTotal,
  required String grandTotal,
  Value<String?> notes,
  required String createdByUserId,
  Value<String?> cancelRequestId,
  Value<String?> cancelRequestHash,
  Value<String?> canceledByUserId,
  Value<String?> cancelReason,
  Value<String?> canceledAt,
  required String createdAt,
  Value<int> rowid,
});
typedef $$InvoicesTableUpdateCompanionBuilder = InvoicesCompanion Function({
  Value<String> id,
  Value<String> requestId,
  Value<String> requestHash,
  Value<int> invoiceNumber,
  Value<String> sellerId,
  Value<String> sellerName,
  Value<String> sellerAddress,
  Value<String?> sellerState,
  Value<String?> sellerStateCode,
  Value<String?> sellerPhone,
  Value<String?> sellerGstin,
  Value<String> placeOfSupplyState,
  Value<String> placeOfSupplyStateCode,
  Value<String> companyName,
  Value<String> companyAddress,
  Value<String> companyCity,
  Value<String> companyState,
  Value<String> companyStateCode,
  Value<String?> companyGstin,
  Value<String?> companyPhone,
  Value<String?> companyEmail,
  Value<String?> companyBankName,
  Value<String?> companyBankAccount,
  Value<String?> companyBankIfsc,
  Value<String?> companyBankBranch,
  Value<String?> companyJurisdiction,
  Value<String> invoiceDate,
  Value<String> taxRegime,
  Value<String> status,
  Value<String> paymentMode,
  Value<String> subtotal,
  Value<String> discountTotal,
  Value<String> taxableTotal,
  Value<String> gstTotal,
  Value<String> grandTotal,
  Value<String?> notes,
  Value<String> createdByUserId,
  Value<String?> cancelRequestId,
  Value<String?> cancelRequestHash,
  Value<String?> canceledByUserId,
  Value<String?> cancelReason,
  Value<String?> canceledAt,
  Value<String> createdAt,
  Value<int> rowid,
});

final class $$InvoicesTableReferences
    extends BaseReferences<_$LocalDatabase, $InvoicesTable, Invoice> {
  $$InvoicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SellersTable _sellerIdTable(_$LocalDatabase db) => db.sellers
      .createAlias($_aliasNameGenerator(db.invoices.sellerId, db.sellers.id));

  $$SellersTableProcessedTableManager get sellerId {
    final $_column = $_itemColumn<String>('seller_id')!;

    final manager = $$SellersTableTableManager($_db, $_db.sellers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sellerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LocalUsersTable _createdByUserIdTable(_$LocalDatabase db) =>
      db.localUsers.createAlias(
          $_aliasNameGenerator(db.invoices.createdByUserId, db.localUsers.id));

  $$LocalUsersTableProcessedTableManager get createdByUserId {
    final $_column = $_itemColumn<String>('created_by_user_id')!;

    final manager = $$LocalUsersTableTableManager($_db, $_db.localUsers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LocalUsersTable _canceledByUserIdTable(_$LocalDatabase db) =>
      db.localUsers.createAlias(
          $_aliasNameGenerator(db.invoices.canceledByUserId, db.localUsers.id));

  $$LocalUsersTableProcessedTableManager? get canceledByUserId {
    final $_column = $_itemColumn<String>('canceled_by_user_id');
    if ($_column == null) return null;
    final manager = $$LocalUsersTableTableManager($_db, $_db.localUsers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_canceledByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$StockMovementsTable, List<StockMovement>>
      _stockMovementsRefsTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.stockMovements,
              aliasName: $_aliasNameGenerator(
                  db.invoices.id, db.stockMovements.invoiceId));

  $$StockMovementsTableProcessedTableManager get stockMovementsRefs {
    final manager = $$StockMovementsTableTableManager($_db, $_db.stockMovements)
        .filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SellerTransactionsTable, List<SellerTransaction>>
      _sellerTransactionsRefsTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.sellerTransactions,
              aliasName: $_aliasNameGenerator(
                  db.invoices.id, db.sellerTransactions.invoiceId));

  $$SellerTransactionsTableProcessedTableManager get sellerTransactionsRefs {
    final manager = $$SellerTransactionsTableTableManager(
            $_db, $_db.sellerTransactions)
        .filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_sellerTransactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InvoiceItemsTable, List<InvoiceItem>>
      _invoiceItemsRefsTable(_$LocalDatabase db) =>
          MultiTypedResultKey.fromTable(db.invoiceItems,
              aliasName: $_aliasNameGenerator(
                  db.invoices.id, db.invoiceItems.invoiceId));

  $$InvoiceItemsTableProcessedTableManager get invoiceItemsRefs {
    final manager = $$InvoiceItemsTableTableManager($_db, $_db.invoiceItems)
        .filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invoiceItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$InvoicesTableFilterComposer
    extends Composer<_$LocalDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestId => $composableBuilder(
      column: $table.requestId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestHash => $composableBuilder(
      column: $table.requestHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sellerName => $composableBuilder(
      column: $table.sellerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sellerAddress => $composableBuilder(
      column: $table.sellerAddress, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sellerState => $composableBuilder(
      column: $table.sellerState, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sellerStateCode => $composableBuilder(
      column: $table.sellerStateCode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sellerPhone => $composableBuilder(
      column: $table.sellerPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sellerGstin => $composableBuilder(
      column: $table.sellerGstin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get placeOfSupplyState => $composableBuilder(
      column: $table.placeOfSupplyState,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get placeOfSupplyStateCode => $composableBuilder(
      column: $table.placeOfSupplyStateCode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyAddress => $composableBuilder(
      column: $table.companyAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyCity => $composableBuilder(
      column: $table.companyCity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyState => $composableBuilder(
      column: $table.companyState, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyStateCode => $composableBuilder(
      column: $table.companyStateCode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyGstin => $composableBuilder(
      column: $table.companyGstin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyPhone => $composableBuilder(
      column: $table.companyPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyEmail => $composableBuilder(
      column: $table.companyEmail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyBankName => $composableBuilder(
      column: $table.companyBankName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyBankAccount => $composableBuilder(
      column: $table.companyBankAccount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyBankIfsc => $composableBuilder(
      column: $table.companyBankIfsc,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyBankBranch => $composableBuilder(
      column: $table.companyBankBranch,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get companyJurisdiction => $composableBuilder(
      column: $table.companyJurisdiction,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceDate => $composableBuilder(
      column: $table.invoiceDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taxRegime => $composableBuilder(
      column: $table.taxRegime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMode => $composableBuilder(
      column: $table.paymentMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get discountTotal => $composableBuilder(
      column: $table.discountTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taxableTotal => $composableBuilder(
      column: $table.taxableTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gstTotal => $composableBuilder(
      column: $table.gstTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get grandTotal => $composableBuilder(
      column: $table.grandTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cancelRequestId => $composableBuilder(
      column: $table.cancelRequestId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cancelRequestHash => $composableBuilder(
      column: $table.cancelRequestHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cancelReason => $composableBuilder(
      column: $table.cancelReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get canceledAt => $composableBuilder(
      column: $table.canceledAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SellersTableFilterComposer get sellerId {
    final $$SellersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sellerId,
        referencedTable: $db.sellers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SellersTableFilterComposer(
              $db: $db,
              $table: $db.sellers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableFilterComposer get createdByUserId {
    final $$LocalUsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableFilterComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableFilterComposer get canceledByUserId {
    final $$LocalUsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.canceledByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableFilterComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> stockMovementsRefs(
      Expression<bool> Function($$StockMovementsTableFilterComposer f) f) {
    final $$StockMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableFilterComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> sellerTransactionsRefs(
      Expression<bool> Function($$SellerTransactionsTableFilterComposer f) f) {
    final $$SellerTransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.sellerTransactions,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SellerTransactionsTableFilterComposer(
              $db: $db,
              $table: $db.sellerTransactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> invoiceItemsRefs(
      Expression<bool> Function($$InvoiceItemsTableFilterComposer f) f) {
    final $$InvoiceItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoiceItems,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoiceItemsTableFilterComposer(
              $db: $db,
              $table: $db.invoiceItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$LocalDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestId => $composableBuilder(
      column: $table.requestId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestHash => $composableBuilder(
      column: $table.requestHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sellerName => $composableBuilder(
      column: $table.sellerName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sellerAddress => $composableBuilder(
      column: $table.sellerAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sellerState => $composableBuilder(
      column: $table.sellerState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sellerStateCode => $composableBuilder(
      column: $table.sellerStateCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sellerPhone => $composableBuilder(
      column: $table.sellerPhone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sellerGstin => $composableBuilder(
      column: $table.sellerGstin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get placeOfSupplyState => $composableBuilder(
      column: $table.placeOfSupplyState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get placeOfSupplyStateCode => $composableBuilder(
      column: $table.placeOfSupplyStateCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyAddress => $composableBuilder(
      column: $table.companyAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyCity => $composableBuilder(
      column: $table.companyCity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyState => $composableBuilder(
      column: $table.companyState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyStateCode => $composableBuilder(
      column: $table.companyStateCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyGstin => $composableBuilder(
      column: $table.companyGstin,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyPhone => $composableBuilder(
      column: $table.companyPhone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyEmail => $composableBuilder(
      column: $table.companyEmail,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyBankName => $composableBuilder(
      column: $table.companyBankName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyBankAccount => $composableBuilder(
      column: $table.companyBankAccount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyBankIfsc => $composableBuilder(
      column: $table.companyBankIfsc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyBankBranch => $composableBuilder(
      column: $table.companyBankBranch,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get companyJurisdiction => $composableBuilder(
      column: $table.companyJurisdiction,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceDate => $composableBuilder(
      column: $table.invoiceDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taxRegime => $composableBuilder(
      column: $table.taxRegime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMode => $composableBuilder(
      column: $table.paymentMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get discountTotal => $composableBuilder(
      column: $table.discountTotal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taxableTotal => $composableBuilder(
      column: $table.taxableTotal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gstTotal => $composableBuilder(
      column: $table.gstTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grandTotal => $composableBuilder(
      column: $table.grandTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cancelRequestId => $composableBuilder(
      column: $table.cancelRequestId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cancelRequestHash => $composableBuilder(
      column: $table.cancelRequestHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cancelReason => $composableBuilder(
      column: $table.cancelReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get canceledAt => $composableBuilder(
      column: $table.canceledAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SellersTableOrderingComposer get sellerId {
    final $$SellersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sellerId,
        referencedTable: $db.sellers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SellersTableOrderingComposer(
              $db: $db,
              $table: $db.sellers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableOrderingComposer get createdByUserId {
    final $$LocalUsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableOrderingComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableOrderingComposer get canceledByUserId {
    final $$LocalUsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.canceledByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableOrderingComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get requestHash => $composableBuilder(
      column: $table.requestHash, builder: (column) => column);

  GeneratedColumn<int> get invoiceNumber => $composableBuilder(
      column: $table.invoiceNumber, builder: (column) => column);

  GeneratedColumn<String> get sellerName => $composableBuilder(
      column: $table.sellerName, builder: (column) => column);

  GeneratedColumn<String> get sellerAddress => $composableBuilder(
      column: $table.sellerAddress, builder: (column) => column);

  GeneratedColumn<String> get sellerState => $composableBuilder(
      column: $table.sellerState, builder: (column) => column);

  GeneratedColumn<String> get sellerStateCode => $composableBuilder(
      column: $table.sellerStateCode, builder: (column) => column);

  GeneratedColumn<String> get sellerPhone => $composableBuilder(
      column: $table.sellerPhone, builder: (column) => column);

  GeneratedColumn<String> get sellerGstin => $composableBuilder(
      column: $table.sellerGstin, builder: (column) => column);

  GeneratedColumn<String> get placeOfSupplyState => $composableBuilder(
      column: $table.placeOfSupplyState, builder: (column) => column);

  GeneratedColumn<String> get placeOfSupplyStateCode => $composableBuilder(
      column: $table.placeOfSupplyStateCode, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
      column: $table.companyName, builder: (column) => column);

  GeneratedColumn<String> get companyAddress => $composableBuilder(
      column: $table.companyAddress, builder: (column) => column);

  GeneratedColumn<String> get companyCity => $composableBuilder(
      column: $table.companyCity, builder: (column) => column);

  GeneratedColumn<String> get companyState => $composableBuilder(
      column: $table.companyState, builder: (column) => column);

  GeneratedColumn<String> get companyStateCode => $composableBuilder(
      column: $table.companyStateCode, builder: (column) => column);

  GeneratedColumn<String> get companyGstin => $composableBuilder(
      column: $table.companyGstin, builder: (column) => column);

  GeneratedColumn<String> get companyPhone => $composableBuilder(
      column: $table.companyPhone, builder: (column) => column);

  GeneratedColumn<String> get companyEmail => $composableBuilder(
      column: $table.companyEmail, builder: (column) => column);

  GeneratedColumn<String> get companyBankName => $composableBuilder(
      column: $table.companyBankName, builder: (column) => column);

  GeneratedColumn<String> get companyBankAccount => $composableBuilder(
      column: $table.companyBankAccount, builder: (column) => column);

  GeneratedColumn<String> get companyBankIfsc => $composableBuilder(
      column: $table.companyBankIfsc, builder: (column) => column);

  GeneratedColumn<String> get companyBankBranch => $composableBuilder(
      column: $table.companyBankBranch, builder: (column) => column);

  GeneratedColumn<String> get companyJurisdiction => $composableBuilder(
      column: $table.companyJurisdiction, builder: (column) => column);

  GeneratedColumn<String> get invoiceDate => $composableBuilder(
      column: $table.invoiceDate, builder: (column) => column);

  GeneratedColumn<String> get taxRegime =>
      $composableBuilder(column: $table.taxRegime, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get paymentMode => $composableBuilder(
      column: $table.paymentMode, builder: (column) => column);

  GeneratedColumn<String> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<String> get discountTotal => $composableBuilder(
      column: $table.discountTotal, builder: (column) => column);

  GeneratedColumn<String> get taxableTotal => $composableBuilder(
      column: $table.taxableTotal, builder: (column) => column);

  GeneratedColumn<String> get gstTotal =>
      $composableBuilder(column: $table.gstTotal, builder: (column) => column);

  GeneratedColumn<String> get grandTotal => $composableBuilder(
      column: $table.grandTotal, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get cancelRequestId => $composableBuilder(
      column: $table.cancelRequestId, builder: (column) => column);

  GeneratedColumn<String> get cancelRequestHash => $composableBuilder(
      column: $table.cancelRequestHash, builder: (column) => column);

  GeneratedColumn<String> get cancelReason => $composableBuilder(
      column: $table.cancelReason, builder: (column) => column);

  GeneratedColumn<String> get canceledAt => $composableBuilder(
      column: $table.canceledAt, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SellersTableAnnotationComposer get sellerId {
    final $$SellersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sellerId,
        referencedTable: $db.sellers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SellersTableAnnotationComposer(
              $db: $db,
              $table: $db.sellers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableAnnotationComposer get createdByUserId {
    final $$LocalUsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableAnnotationComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableAnnotationComposer get canceledByUserId {
    final $$LocalUsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.canceledByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableAnnotationComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> stockMovementsRefs<T extends Object>(
      Expression<T> Function($$StockMovementsTableAnnotationComposer a) f) {
    final $$StockMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.stockMovements,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StockMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.stockMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> sellerTransactionsRefs<T extends Object>(
      Expression<T> Function($$SellerTransactionsTableAnnotationComposer a) f) {
    final $$SellerTransactionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.sellerTransactions,
            getReferencedColumn: (t) => t.invoiceId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SellerTransactionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.sellerTransactions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> invoiceItemsRefs<T extends Object>(
      Expression<T> Function($$InvoiceItemsTableAnnotationComposer a) f) {
    final $$InvoiceItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.invoiceItems,
        getReferencedColumn: (t) => t.invoiceId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoiceItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.invoiceItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$InvoicesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $InvoicesTable,
    Invoice,
    $$InvoicesTableFilterComposer,
    $$InvoicesTableOrderingComposer,
    $$InvoicesTableAnnotationComposer,
    $$InvoicesTableCreateCompanionBuilder,
    $$InvoicesTableUpdateCompanionBuilder,
    (Invoice, $$InvoicesTableReferences),
    Invoice,
    PrefetchHooks Function(
        {bool sellerId,
        bool createdByUserId,
        bool canceledByUserId,
        bool stockMovementsRefs,
        bool sellerTransactionsRefs,
        bool invoiceItemsRefs})> {
  $$InvoicesTableTableManager(_$LocalDatabase db, $InvoicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> requestId = const Value.absent(),
            Value<String> requestHash = const Value.absent(),
            Value<int> invoiceNumber = const Value.absent(),
            Value<String> sellerId = const Value.absent(),
            Value<String> sellerName = const Value.absent(),
            Value<String> sellerAddress = const Value.absent(),
            Value<String?> sellerState = const Value.absent(),
            Value<String?> sellerStateCode = const Value.absent(),
            Value<String?> sellerPhone = const Value.absent(),
            Value<String?> sellerGstin = const Value.absent(),
            Value<String> placeOfSupplyState = const Value.absent(),
            Value<String> placeOfSupplyStateCode = const Value.absent(),
            Value<String> companyName = const Value.absent(),
            Value<String> companyAddress = const Value.absent(),
            Value<String> companyCity = const Value.absent(),
            Value<String> companyState = const Value.absent(),
            Value<String> companyStateCode = const Value.absent(),
            Value<String?> companyGstin = const Value.absent(),
            Value<String?> companyPhone = const Value.absent(),
            Value<String?> companyEmail = const Value.absent(),
            Value<String?> companyBankName = const Value.absent(),
            Value<String?> companyBankAccount = const Value.absent(),
            Value<String?> companyBankIfsc = const Value.absent(),
            Value<String?> companyBankBranch = const Value.absent(),
            Value<String?> companyJurisdiction = const Value.absent(),
            Value<String> invoiceDate = const Value.absent(),
            Value<String> taxRegime = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> paymentMode = const Value.absent(),
            Value<String> subtotal = const Value.absent(),
            Value<String> discountTotal = const Value.absent(),
            Value<String> taxableTotal = const Value.absent(),
            Value<String> gstTotal = const Value.absent(),
            Value<String> grandTotal = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> createdByUserId = const Value.absent(),
            Value<String?> cancelRequestId = const Value.absent(),
            Value<String?> cancelRequestHash = const Value.absent(),
            Value<String?> canceledByUserId = const Value.absent(),
            Value<String?> cancelReason = const Value.absent(),
            Value<String?> canceledAt = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvoicesCompanion(
            id: id,
            requestId: requestId,
            requestHash: requestHash,
            invoiceNumber: invoiceNumber,
            sellerId: sellerId,
            sellerName: sellerName,
            sellerAddress: sellerAddress,
            sellerState: sellerState,
            sellerStateCode: sellerStateCode,
            sellerPhone: sellerPhone,
            sellerGstin: sellerGstin,
            placeOfSupplyState: placeOfSupplyState,
            placeOfSupplyStateCode: placeOfSupplyStateCode,
            companyName: companyName,
            companyAddress: companyAddress,
            companyCity: companyCity,
            companyState: companyState,
            companyStateCode: companyStateCode,
            companyGstin: companyGstin,
            companyPhone: companyPhone,
            companyEmail: companyEmail,
            companyBankName: companyBankName,
            companyBankAccount: companyBankAccount,
            companyBankIfsc: companyBankIfsc,
            companyBankBranch: companyBankBranch,
            companyJurisdiction: companyJurisdiction,
            invoiceDate: invoiceDate,
            taxRegime: taxRegime,
            status: status,
            paymentMode: paymentMode,
            subtotal: subtotal,
            discountTotal: discountTotal,
            taxableTotal: taxableTotal,
            gstTotal: gstTotal,
            grandTotal: grandTotal,
            notes: notes,
            createdByUserId: createdByUserId,
            cancelRequestId: cancelRequestId,
            cancelRequestHash: cancelRequestHash,
            canceledByUserId: canceledByUserId,
            cancelReason: cancelReason,
            canceledAt: canceledAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String requestId,
            required String requestHash,
            required int invoiceNumber,
            required String sellerId,
            required String sellerName,
            required String sellerAddress,
            Value<String?> sellerState = const Value.absent(),
            Value<String?> sellerStateCode = const Value.absent(),
            Value<String?> sellerPhone = const Value.absent(),
            Value<String?> sellerGstin = const Value.absent(),
            required String placeOfSupplyState,
            required String placeOfSupplyStateCode,
            required String companyName,
            required String companyAddress,
            required String companyCity,
            required String companyState,
            required String companyStateCode,
            Value<String?> companyGstin = const Value.absent(),
            Value<String?> companyPhone = const Value.absent(),
            Value<String?> companyEmail = const Value.absent(),
            Value<String?> companyBankName = const Value.absent(),
            Value<String?> companyBankAccount = const Value.absent(),
            Value<String?> companyBankIfsc = const Value.absent(),
            Value<String?> companyBankBranch = const Value.absent(),
            Value<String?> companyJurisdiction = const Value.absent(),
            required String invoiceDate,
            required String taxRegime,
            required String status,
            required String paymentMode,
            required String subtotal,
            required String discountTotal,
            required String taxableTotal,
            required String gstTotal,
            required String grandTotal,
            Value<String?> notes = const Value.absent(),
            required String createdByUserId,
            Value<String?> cancelRequestId = const Value.absent(),
            Value<String?> cancelRequestHash = const Value.absent(),
            Value<String?> canceledByUserId = const Value.absent(),
            Value<String?> cancelReason = const Value.absent(),
            Value<String?> canceledAt = const Value.absent(),
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              InvoicesCompanion.insert(
            id: id,
            requestId: requestId,
            requestHash: requestHash,
            invoiceNumber: invoiceNumber,
            sellerId: sellerId,
            sellerName: sellerName,
            sellerAddress: sellerAddress,
            sellerState: sellerState,
            sellerStateCode: sellerStateCode,
            sellerPhone: sellerPhone,
            sellerGstin: sellerGstin,
            placeOfSupplyState: placeOfSupplyState,
            placeOfSupplyStateCode: placeOfSupplyStateCode,
            companyName: companyName,
            companyAddress: companyAddress,
            companyCity: companyCity,
            companyState: companyState,
            companyStateCode: companyStateCode,
            companyGstin: companyGstin,
            companyPhone: companyPhone,
            companyEmail: companyEmail,
            companyBankName: companyBankName,
            companyBankAccount: companyBankAccount,
            companyBankIfsc: companyBankIfsc,
            companyBankBranch: companyBankBranch,
            companyJurisdiction: companyJurisdiction,
            invoiceDate: invoiceDate,
            taxRegime: taxRegime,
            status: status,
            paymentMode: paymentMode,
            subtotal: subtotal,
            discountTotal: discountTotal,
            taxableTotal: taxableTotal,
            gstTotal: gstTotal,
            grandTotal: grandTotal,
            notes: notes,
            createdByUserId: createdByUserId,
            cancelRequestId: cancelRequestId,
            cancelRequestHash: cancelRequestHash,
            canceledByUserId: canceledByUserId,
            cancelReason: cancelReason,
            canceledAt: canceledAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$InvoicesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {sellerId = false,
              createdByUserId = false,
              canceledByUserId = false,
              stockMovementsRefs = false,
              sellerTransactionsRefs = false,
              invoiceItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (stockMovementsRefs) db.stockMovements,
                if (sellerTransactionsRefs) db.sellerTransactions,
                if (invoiceItemsRefs) db.invoiceItems
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sellerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sellerId,
                    referencedTable:
                        $$InvoicesTableReferences._sellerIdTable(db),
                    referencedColumn:
                        $$InvoicesTableReferences._sellerIdTable(db).id,
                  ) as T;
                }
                if (createdByUserId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.createdByUserId,
                    referencedTable:
                        $$InvoicesTableReferences._createdByUserIdTable(db),
                    referencedColumn:
                        $$InvoicesTableReferences._createdByUserIdTable(db).id,
                  ) as T;
                }
                if (canceledByUserId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.canceledByUserId,
                    referencedTable:
                        $$InvoicesTableReferences._canceledByUserIdTable(db),
                    referencedColumn:
                        $$InvoicesTableReferences._canceledByUserIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stockMovementsRefs)
                    await $_getPrefetchedData<Invoice, $InvoicesTable,
                            StockMovement>(
                        currentTable: table,
                        referencedTable: $$InvoicesTableReferences
                            ._stockMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InvoicesTableReferences(db, table, p0)
                                .stockMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.invoiceId == item.id),
                        typedResults: items),
                  if (sellerTransactionsRefs)
                    await $_getPrefetchedData<Invoice, $InvoicesTable,
                            SellerTransaction>(
                        currentTable: table,
                        referencedTable: $$InvoicesTableReferences
                            ._sellerTransactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InvoicesTableReferences(db, table, p0)
                                .sellerTransactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.invoiceId == item.id),
                        typedResults: items),
                  if (invoiceItemsRefs)
                    await $_getPrefetchedData<Invoice, $InvoicesTable,
                            InvoiceItem>(
                        currentTable: table,
                        referencedTable: $$InvoicesTableReferences
                            ._invoiceItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InvoicesTableReferences(db, table, p0)
                                .invoiceItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.invoiceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$InvoicesTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $InvoicesTable,
    Invoice,
    $$InvoicesTableFilterComposer,
    $$InvoicesTableOrderingComposer,
    $$InvoicesTableAnnotationComposer,
    $$InvoicesTableCreateCompanionBuilder,
    $$InvoicesTableUpdateCompanionBuilder,
    (Invoice, $$InvoicesTableReferences),
    Invoice,
    PrefetchHooks Function(
        {bool sellerId,
        bool createdByUserId,
        bool canceledByUserId,
        bool stockMovementsRefs,
        bool sellerTransactionsRefs,
        bool invoiceItemsRefs})>;
typedef $$StockMovementsTableCreateCompanionBuilder = StockMovementsCompanion
    Function({
  required String id,
  required String productId,
  Value<String?> invoiceId,
  Value<String?> requestId,
  Value<String?> requestHash,
  required String movementType,
  required String quantityDelta,
  Value<String?> reason,
  required String createdByUserId,
  required String createdAt,
  Value<int> rowid,
});
typedef $$StockMovementsTableUpdateCompanionBuilder = StockMovementsCompanion
    Function({
  Value<String> id,
  Value<String> productId,
  Value<String?> invoiceId,
  Value<String?> requestId,
  Value<String?> requestHash,
  Value<String> movementType,
  Value<String> quantityDelta,
  Value<String?> reason,
  Value<String> createdByUserId,
  Value<String> createdAt,
  Value<int> rowid,
});

final class $$StockMovementsTableReferences extends BaseReferences<
    _$LocalDatabase, $StockMovementsTable, StockMovement> {
  $$StockMovementsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$LocalDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.stockMovements.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $InvoicesTable _invoiceIdTable(_$LocalDatabase db) =>
      db.invoices.createAlias(
          $_aliasNameGenerator(db.stockMovements.invoiceId, db.invoices.id));

  $$InvoicesTableProcessedTableManager? get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id');
    if ($_column == null) return null;
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LocalUsersTable _createdByUserIdTable(_$LocalDatabase db) =>
      db.localUsers.createAlias($_aliasNameGenerator(
          db.stockMovements.createdByUserId, db.localUsers.id));

  $$LocalUsersTableProcessedTableManager get createdByUserId {
    final $_column = $_itemColumn<String>('created_by_user_id')!;

    final manager = $$LocalUsersTableTableManager($_db, $_db.localUsers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StockMovementsTableFilterComposer
    extends Composer<_$LocalDatabase, $StockMovementsTable> {
  $$StockMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestId => $composableBuilder(
      column: $table.requestId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestHash => $composableBuilder(
      column: $table.requestHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get movementType => $composableBuilder(
      column: $table.movementType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quantityDelta => $composableBuilder(
      column: $table.quantityDelta, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableFilterComposer get createdByUserId {
    final $$LocalUsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableFilterComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockMovementsTableOrderingComposer
    extends Composer<_$LocalDatabase, $StockMovementsTable> {
  $$StockMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestId => $composableBuilder(
      column: $table.requestId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestHash => $composableBuilder(
      column: $table.requestHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get movementType => $composableBuilder(
      column: $table.movementType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quantityDelta => $composableBuilder(
      column: $table.quantityDelta,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableOrderingComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableOrderingComposer get createdByUserId {
    final $$LocalUsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableOrderingComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockMovementsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $StockMovementsTable> {
  $$StockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get requestHash => $composableBuilder(
      column: $table.requestHash, builder: (column) => column);

  GeneratedColumn<String> get movementType => $composableBuilder(
      column: $table.movementType, builder: (column) => column);

  GeneratedColumn<String> get quantityDelta => $composableBuilder(
      column: $table.quantityDelta, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableAnnotationComposer get createdByUserId {
    final $$LocalUsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableAnnotationComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StockMovementsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $StockMovementsTable,
    StockMovement,
    $$StockMovementsTableFilterComposer,
    $$StockMovementsTableOrderingComposer,
    $$StockMovementsTableAnnotationComposer,
    $$StockMovementsTableCreateCompanionBuilder,
    $$StockMovementsTableUpdateCompanionBuilder,
    (StockMovement, $$StockMovementsTableReferences),
    StockMovement,
    PrefetchHooks Function(
        {bool productId, bool invoiceId, bool createdByUserId})> {
  $$StockMovementsTableTableManager(
      _$LocalDatabase db, $StockMovementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String?> invoiceId = const Value.absent(),
            Value<String?> requestId = const Value.absent(),
            Value<String?> requestHash = const Value.absent(),
            Value<String> movementType = const Value.absent(),
            Value<String> quantityDelta = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<String> createdByUserId = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StockMovementsCompanion(
            id: id,
            productId: productId,
            invoiceId: invoiceId,
            requestId: requestId,
            requestHash: requestHash,
            movementType: movementType,
            quantityDelta: quantityDelta,
            reason: reason,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String productId,
            Value<String?> invoiceId = const Value.absent(),
            Value<String?> requestId = const Value.absent(),
            Value<String?> requestHash = const Value.absent(),
            required String movementType,
            required String quantityDelta,
            Value<String?> reason = const Value.absent(),
            required String createdByUserId,
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StockMovementsCompanion.insert(
            id: id,
            productId: productId,
            invoiceId: invoiceId,
            requestId: requestId,
            requestHash: requestHash,
            movementType: movementType,
            quantityDelta: quantityDelta,
            reason: reason,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StockMovementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {productId = false, invoiceId = false, createdByUserId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$StockMovementsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$StockMovementsTableReferences._productIdTable(db).id,
                  ) as T;
                }
                if (invoiceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.invoiceId,
                    referencedTable:
                        $$StockMovementsTableReferences._invoiceIdTable(db),
                    referencedColumn:
                        $$StockMovementsTableReferences._invoiceIdTable(db).id,
                  ) as T;
                }
                if (createdByUserId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.createdByUserId,
                    referencedTable: $$StockMovementsTableReferences
                        ._createdByUserIdTable(db),
                    referencedColumn: $$StockMovementsTableReferences
                        ._createdByUserIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$StockMovementsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $StockMovementsTable,
    StockMovement,
    $$StockMovementsTableFilterComposer,
    $$StockMovementsTableOrderingComposer,
    $$StockMovementsTableAnnotationComposer,
    $$StockMovementsTableCreateCompanionBuilder,
    $$StockMovementsTableUpdateCompanionBuilder,
    (StockMovement, $$StockMovementsTableReferences),
    StockMovement,
    PrefetchHooks Function(
        {bool productId, bool invoiceId, bool createdByUserId})>;
typedef $$SellerTransactionsTableCreateCompanionBuilder
    = SellerTransactionsCompanion Function({
  required String id,
  required String sellerId,
  Value<String?> invoiceId,
  Value<String?> requestId,
  Value<String?> requestHash,
  Value<String?> openingBalanceSellerId,
  required String entryType,
  required String amount,
  required String occurredOn,
  Value<String?> notes,
  required String createdByUserId,
  required String createdAt,
  Value<int> rowid,
});
typedef $$SellerTransactionsTableUpdateCompanionBuilder
    = SellerTransactionsCompanion Function({
  Value<String> id,
  Value<String> sellerId,
  Value<String?> invoiceId,
  Value<String?> requestId,
  Value<String?> requestHash,
  Value<String?> openingBalanceSellerId,
  Value<String> entryType,
  Value<String> amount,
  Value<String> occurredOn,
  Value<String?> notes,
  Value<String> createdByUserId,
  Value<String> createdAt,
  Value<int> rowid,
});

final class $$SellerTransactionsTableReferences extends BaseReferences<
    _$LocalDatabase, $SellerTransactionsTable, SellerTransaction> {
  $$SellerTransactionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SellersTable _sellerIdTable(_$LocalDatabase db) =>
      db.sellers.createAlias(
          $_aliasNameGenerator(db.sellerTransactions.sellerId, db.sellers.id));

  $$SellersTableProcessedTableManager get sellerId {
    final $_column = $_itemColumn<String>('seller_id')!;

    final manager = $$SellersTableTableManager($_db, $_db.sellers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sellerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $InvoicesTable _invoiceIdTable(_$LocalDatabase db) =>
      db.invoices.createAlias($_aliasNameGenerator(
          db.sellerTransactions.invoiceId, db.invoices.id));

  $$InvoicesTableProcessedTableManager? get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id');
    if ($_column == null) return null;
    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LocalUsersTable _createdByUserIdTable(_$LocalDatabase db) =>
      db.localUsers.createAlias($_aliasNameGenerator(
          db.sellerTransactions.createdByUserId, db.localUsers.id));

  $$LocalUsersTableProcessedTableManager get createdByUserId {
    final $_column = $_itemColumn<String>('created_by_user_id')!;

    final manager = $$LocalUsersTableTableManager($_db, $_db.localUsers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SellerTransactionsTableFilterComposer
    extends Composer<_$LocalDatabase, $SellerTransactionsTable> {
  $$SellerTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestId => $composableBuilder(
      column: $table.requestId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestHash => $composableBuilder(
      column: $table.requestHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get openingBalanceSellerId => $composableBuilder(
      column: $table.openingBalanceSellerId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryType => $composableBuilder(
      column: $table.entryType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get occurredOn => $composableBuilder(
      column: $table.occurredOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SellersTableFilterComposer get sellerId {
    final $$SellersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sellerId,
        referencedTable: $db.sellers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SellersTableFilterComposer(
              $db: $db,
              $table: $db.sellers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableFilterComposer get createdByUserId {
    final $$LocalUsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableFilterComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SellerTransactionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $SellerTransactionsTable> {
  $$SellerTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestId => $composableBuilder(
      column: $table.requestId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestHash => $composableBuilder(
      column: $table.requestHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get openingBalanceSellerId => $composableBuilder(
      column: $table.openingBalanceSellerId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryType => $composableBuilder(
      column: $table.entryType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get occurredOn => $composableBuilder(
      column: $table.occurredOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SellersTableOrderingComposer get sellerId {
    final $$SellersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sellerId,
        referencedTable: $db.sellers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SellersTableOrderingComposer(
              $db: $db,
              $table: $db.sellers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableOrderingComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableOrderingComposer get createdByUserId {
    final $$LocalUsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableOrderingComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SellerTransactionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $SellerTransactionsTable> {
  $$SellerTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get requestHash => $composableBuilder(
      column: $table.requestHash, builder: (column) => column);

  GeneratedColumn<String> get openingBalanceSellerId => $composableBuilder(
      column: $table.openingBalanceSellerId, builder: (column) => column);

  GeneratedColumn<String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get occurredOn => $composableBuilder(
      column: $table.occurredOn, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SellersTableAnnotationComposer get sellerId {
    final $$SellersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sellerId,
        referencedTable: $db.sellers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SellersTableAnnotationComposer(
              $db: $db,
              $table: $db.sellers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$LocalUsersTableAnnotationComposer get createdByUserId {
    final $$LocalUsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdByUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableAnnotationComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SellerTransactionsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $SellerTransactionsTable,
    SellerTransaction,
    $$SellerTransactionsTableFilterComposer,
    $$SellerTransactionsTableOrderingComposer,
    $$SellerTransactionsTableAnnotationComposer,
    $$SellerTransactionsTableCreateCompanionBuilder,
    $$SellerTransactionsTableUpdateCompanionBuilder,
    (SellerTransaction, $$SellerTransactionsTableReferences),
    SellerTransaction,
    PrefetchHooks Function(
        {bool sellerId, bool invoiceId, bool createdByUserId})> {
  $$SellerTransactionsTableTableManager(
      _$LocalDatabase db, $SellerTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SellerTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SellerTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SellerTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sellerId = const Value.absent(),
            Value<String?> invoiceId = const Value.absent(),
            Value<String?> requestId = const Value.absent(),
            Value<String?> requestHash = const Value.absent(),
            Value<String?> openingBalanceSellerId = const Value.absent(),
            Value<String> entryType = const Value.absent(),
            Value<String> amount = const Value.absent(),
            Value<String> occurredOn = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> createdByUserId = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SellerTransactionsCompanion(
            id: id,
            sellerId: sellerId,
            invoiceId: invoiceId,
            requestId: requestId,
            requestHash: requestHash,
            openingBalanceSellerId: openingBalanceSellerId,
            entryType: entryType,
            amount: amount,
            occurredOn: occurredOn,
            notes: notes,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sellerId,
            Value<String?> invoiceId = const Value.absent(),
            Value<String?> requestId = const Value.absent(),
            Value<String?> requestHash = const Value.absent(),
            Value<String?> openingBalanceSellerId = const Value.absent(),
            required String entryType,
            required String amount,
            required String occurredOn,
            Value<String?> notes = const Value.absent(),
            required String createdByUserId,
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SellerTransactionsCompanion.insert(
            id: id,
            sellerId: sellerId,
            invoiceId: invoiceId,
            requestId: requestId,
            requestHash: requestHash,
            openingBalanceSellerId: openingBalanceSellerId,
            entryType: entryType,
            amount: amount,
            occurredOn: occurredOn,
            notes: notes,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SellerTransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {sellerId = false, invoiceId = false, createdByUserId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sellerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sellerId,
                    referencedTable:
                        $$SellerTransactionsTableReferences._sellerIdTable(db),
                    referencedColumn: $$SellerTransactionsTableReferences
                        ._sellerIdTable(db)
                        .id,
                  ) as T;
                }
                if (invoiceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.invoiceId,
                    referencedTable:
                        $$SellerTransactionsTableReferences._invoiceIdTable(db),
                    referencedColumn: $$SellerTransactionsTableReferences
                        ._invoiceIdTable(db)
                        .id,
                  ) as T;
                }
                if (createdByUserId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.createdByUserId,
                    referencedTable: $$SellerTransactionsTableReferences
                        ._createdByUserIdTable(db),
                    referencedColumn: $$SellerTransactionsTableReferences
                        ._createdByUserIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SellerTransactionsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $SellerTransactionsTable,
    SellerTransaction,
    $$SellerTransactionsTableFilterComposer,
    $$SellerTransactionsTableOrderingComposer,
    $$SellerTransactionsTableAnnotationComposer,
    $$SellerTransactionsTableCreateCompanionBuilder,
    $$SellerTransactionsTableUpdateCompanionBuilder,
    (SellerTransaction, $$SellerTransactionsTableReferences),
    SellerTransaction,
    PrefetchHooks Function(
        {bool sellerId, bool invoiceId, bool createdByUserId})>;
typedef $$CompanyProfilesTableCreateCompanionBuilder = CompanyProfilesCompanion
    Function({
  required String id,
  required String name,
  required String address,
  required String city,
  required String state,
  required String stateCode,
  Value<String?> gstin,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> bankName,
  Value<String?> bankAccount,
  Value<String?> bankIfsc,
  Value<String?> bankBranch,
  Value<String?> jurisdiction,
  Value<bool> isActive,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$CompanyProfilesTableUpdateCompanionBuilder = CompanyProfilesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> address,
  Value<String> city,
  Value<String> state,
  Value<String> stateCode,
  Value<String?> gstin,
  Value<String?> phone,
  Value<String?> email,
  Value<String?> bankName,
  Value<String?> bankAccount,
  Value<String?> bankIfsc,
  Value<String?> bankBranch,
  Value<String?> jurisdiction,
  Value<bool> isActive,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$CompanyProfilesTableFilterComposer
    extends Composer<_$LocalDatabase, $CompanyProfilesTable> {
  $$CompanyProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stateCode => $composableBuilder(
      column: $table.stateCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gstin => $composableBuilder(
      column: $table.gstin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankAccount => $composableBuilder(
      column: $table.bankAccount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankIfsc => $composableBuilder(
      column: $table.bankIfsc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankBranch => $composableBuilder(
      column: $table.bankBranch, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jurisdiction => $composableBuilder(
      column: $table.jurisdiction, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CompanyProfilesTableOrderingComposer
    extends Composer<_$LocalDatabase, $CompanyProfilesTable> {
  $$CompanyProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stateCode => $composableBuilder(
      column: $table.stateCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gstin => $composableBuilder(
      column: $table.gstin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankAccount => $composableBuilder(
      column: $table.bankAccount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankIfsc => $composableBuilder(
      column: $table.bankIfsc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankBranch => $composableBuilder(
      column: $table.bankBranch, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jurisdiction => $composableBuilder(
      column: $table.jurisdiction,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CompanyProfilesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CompanyProfilesTable> {
  $$CompanyProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get stateCode =>
      $composableBuilder(column: $table.stateCode, builder: (column) => column);

  GeneratedColumn<String> get gstin =>
      $composableBuilder(column: $table.gstin, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get bankAccount => $composableBuilder(
      column: $table.bankAccount, builder: (column) => column);

  GeneratedColumn<String> get bankIfsc =>
      $composableBuilder(column: $table.bankIfsc, builder: (column) => column);

  GeneratedColumn<String> get bankBranch => $composableBuilder(
      column: $table.bankBranch, builder: (column) => column);

  GeneratedColumn<String> get jurisdiction => $composableBuilder(
      column: $table.jurisdiction, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CompanyProfilesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $CompanyProfilesTable,
    CompanyProfile,
    $$CompanyProfilesTableFilterComposer,
    $$CompanyProfilesTableOrderingComposer,
    $$CompanyProfilesTableAnnotationComposer,
    $$CompanyProfilesTableCreateCompanionBuilder,
    $$CompanyProfilesTableUpdateCompanionBuilder,
    (
      CompanyProfile,
      BaseReferences<_$LocalDatabase, $CompanyProfilesTable, CompanyProfile>
    ),
    CompanyProfile,
    PrefetchHooks Function()> {
  $$CompanyProfilesTableTableManager(
      _$LocalDatabase db, $CompanyProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompanyProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompanyProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompanyProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<String> city = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<String> stateCode = const Value.absent(),
            Value<String?> gstin = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> bankName = const Value.absent(),
            Value<String?> bankAccount = const Value.absent(),
            Value<String?> bankIfsc = const Value.absent(),
            Value<String?> bankBranch = const Value.absent(),
            Value<String?> jurisdiction = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CompanyProfilesCompanion(
            id: id,
            name: name,
            address: address,
            city: city,
            state: state,
            stateCode: stateCode,
            gstin: gstin,
            phone: phone,
            email: email,
            bankName: bankName,
            bankAccount: bankAccount,
            bankIfsc: bankIfsc,
            bankBranch: bankBranch,
            jurisdiction: jurisdiction,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String address,
            required String city,
            required String state,
            required String stateCode,
            Value<String?> gstin = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> bankName = const Value.absent(),
            Value<String?> bankAccount = const Value.absent(),
            Value<String?> bankIfsc = const Value.absent(),
            Value<String?> bankBranch = const Value.absent(),
            Value<String?> jurisdiction = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CompanyProfilesCompanion.insert(
            id: id,
            name: name,
            address: address,
            city: city,
            state: state,
            stateCode: stateCode,
            gstin: gstin,
            phone: phone,
            email: email,
            bankName: bankName,
            bankAccount: bankAccount,
            bankIfsc: bankIfsc,
            bankBranch: bankBranch,
            jurisdiction: jurisdiction,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CompanyProfilesTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $CompanyProfilesTable,
    CompanyProfile,
    $$CompanyProfilesTableFilterComposer,
    $$CompanyProfilesTableOrderingComposer,
    $$CompanyProfilesTableAnnotationComposer,
    $$CompanyProfilesTableCreateCompanionBuilder,
    $$CompanyProfilesTableUpdateCompanionBuilder,
    (
      CompanyProfile,
      BaseReferences<_$LocalDatabase, $CompanyProfilesTable, CompanyProfile>
    ),
    CompanyProfile,
    PrefetchHooks Function()>;
typedef $$InvoiceItemsTableCreateCompanionBuilder = InvoiceItemsCompanion
    Function({
  required String id,
  required String invoiceId,
  required String productId,
  required int lineNumber,
  required String productName,
  required String productCode,
  required String company,
  required String category,
  required String quantity,
  required String pricingMode,
  required String enteredUnitPrice,
  required String unitPriceExclTax,
  required String unitPriceInclTax,
  required String gstRate,
  required String cgstRate,
  required String sgstRate,
  required String igstRate,
  required String discountPercent,
  required String discountAmount,
  required String taxableAmount,
  required String gstAmount,
  required String cgstAmount,
  required String sgstAmount,
  required String igstAmount,
  required String lineTotal,
  Value<int> rowid,
});
typedef $$InvoiceItemsTableUpdateCompanionBuilder = InvoiceItemsCompanion
    Function({
  Value<String> id,
  Value<String> invoiceId,
  Value<String> productId,
  Value<int> lineNumber,
  Value<String> productName,
  Value<String> productCode,
  Value<String> company,
  Value<String> category,
  Value<String> quantity,
  Value<String> pricingMode,
  Value<String> enteredUnitPrice,
  Value<String> unitPriceExclTax,
  Value<String> unitPriceInclTax,
  Value<String> gstRate,
  Value<String> cgstRate,
  Value<String> sgstRate,
  Value<String> igstRate,
  Value<String> discountPercent,
  Value<String> discountAmount,
  Value<String> taxableAmount,
  Value<String> gstAmount,
  Value<String> cgstAmount,
  Value<String> sgstAmount,
  Value<String> igstAmount,
  Value<String> lineTotal,
  Value<int> rowid,
});

final class $$InvoiceItemsTableReferences
    extends BaseReferences<_$LocalDatabase, $InvoiceItemsTable, InvoiceItem> {
  $$InvoiceItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InvoicesTable _invoiceIdTable(_$LocalDatabase db) =>
      db.invoices.createAlias(
          $_aliasNameGenerator(db.invoiceItems.invoiceId, db.invoices.id));

  $$InvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id')!;

    final manager = $$InvoicesTableTableManager($_db, $_db.invoices)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$LocalDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.invoiceItems.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$InvoiceItemsTableFilterComposer
    extends Composer<_$LocalDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineNumber => $composableBuilder(
      column: $table.lineNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pricingMode => $composableBuilder(
      column: $table.pricingMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enteredUnitPrice => $composableBuilder(
      column: $table.enteredUnitPrice,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitPriceExclTax => $composableBuilder(
      column: $table.unitPriceExclTax,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitPriceInclTax => $composableBuilder(
      column: $table.unitPriceInclTax,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gstRate => $composableBuilder(
      column: $table.gstRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cgstRate => $composableBuilder(
      column: $table.cgstRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sgstRate => $composableBuilder(
      column: $table.sgstRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get igstRate => $composableBuilder(
      column: $table.igstRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get discountPercent => $composableBuilder(
      column: $table.discountPercent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taxableAmount => $composableBuilder(
      column: $table.taxableAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gstAmount => $composableBuilder(
      column: $table.gstAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cgstAmount => $composableBuilder(
      column: $table.cgstAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sgstAmount => $composableBuilder(
      column: $table.sgstAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get igstAmount => $composableBuilder(
      column: $table.igstAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lineTotal => $composableBuilder(
      column: $table.lineTotal, builder: (column) => ColumnFilters(column));

  $$InvoicesTableFilterComposer get invoiceId {
    final $$InvoicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableFilterComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvoiceItemsTableOrderingComposer
    extends Composer<_$LocalDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineNumber => $composableBuilder(
      column: $table.lineNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pricingMode => $composableBuilder(
      column: $table.pricingMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enteredUnitPrice => $composableBuilder(
      column: $table.enteredUnitPrice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitPriceExclTax => $composableBuilder(
      column: $table.unitPriceExclTax,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitPriceInclTax => $composableBuilder(
      column: $table.unitPriceInclTax,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gstRate => $composableBuilder(
      column: $table.gstRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cgstRate => $composableBuilder(
      column: $table.cgstRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sgstRate => $composableBuilder(
      column: $table.sgstRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get igstRate => $composableBuilder(
      column: $table.igstRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get discountPercent => $composableBuilder(
      column: $table.discountPercent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taxableAmount => $composableBuilder(
      column: $table.taxableAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gstAmount => $composableBuilder(
      column: $table.gstAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cgstAmount => $composableBuilder(
      column: $table.cgstAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sgstAmount => $composableBuilder(
      column: $table.sgstAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get igstAmount => $composableBuilder(
      column: $table.igstAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lineTotal => $composableBuilder(
      column: $table.lineTotal, builder: (column) => ColumnOrderings(column));

  $$InvoicesTableOrderingComposer get invoiceId {
    final $$InvoicesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableOrderingComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvoiceItemsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lineNumber => $composableBuilder(
      column: $table.lineNumber, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get pricingMode => $composableBuilder(
      column: $table.pricingMode, builder: (column) => column);

  GeneratedColumn<String> get enteredUnitPrice => $composableBuilder(
      column: $table.enteredUnitPrice, builder: (column) => column);

  GeneratedColumn<String> get unitPriceExclTax => $composableBuilder(
      column: $table.unitPriceExclTax, builder: (column) => column);

  GeneratedColumn<String> get unitPriceInclTax => $composableBuilder(
      column: $table.unitPriceInclTax, builder: (column) => column);

  GeneratedColumn<String> get gstRate =>
      $composableBuilder(column: $table.gstRate, builder: (column) => column);

  GeneratedColumn<String> get cgstRate =>
      $composableBuilder(column: $table.cgstRate, builder: (column) => column);

  GeneratedColumn<String> get sgstRate =>
      $composableBuilder(column: $table.sgstRate, builder: (column) => column);

  GeneratedColumn<String> get igstRate =>
      $composableBuilder(column: $table.igstRate, builder: (column) => column);

  GeneratedColumn<String> get discountPercent => $composableBuilder(
      column: $table.discountPercent, builder: (column) => column);

  GeneratedColumn<String> get discountAmount => $composableBuilder(
      column: $table.discountAmount, builder: (column) => column);

  GeneratedColumn<String> get taxableAmount => $composableBuilder(
      column: $table.taxableAmount, builder: (column) => column);

  GeneratedColumn<String> get gstAmount =>
      $composableBuilder(column: $table.gstAmount, builder: (column) => column);

  GeneratedColumn<String> get cgstAmount => $composableBuilder(
      column: $table.cgstAmount, builder: (column) => column);

  GeneratedColumn<String> get sgstAmount => $composableBuilder(
      column: $table.sgstAmount, builder: (column) => column);

  GeneratedColumn<String> get igstAmount => $composableBuilder(
      column: $table.igstAmount, builder: (column) => column);

  GeneratedColumn<String> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  $$InvoicesTableAnnotationComposer get invoiceId {
    final $$InvoicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.invoiceId,
        referencedTable: $db.invoices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InvoicesTableAnnotationComposer(
              $db: $db,
              $table: $db.invoices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InvoiceItemsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $InvoiceItemsTable,
    InvoiceItem,
    $$InvoiceItemsTableFilterComposer,
    $$InvoiceItemsTableOrderingComposer,
    $$InvoiceItemsTableAnnotationComposer,
    $$InvoiceItemsTableCreateCompanionBuilder,
    $$InvoiceItemsTableUpdateCompanionBuilder,
    (InvoiceItem, $$InvoiceItemsTableReferences),
    InvoiceItem,
    PrefetchHooks Function({bool invoiceId, bool productId})> {
  $$InvoiceItemsTableTableManager(_$LocalDatabase db, $InvoiceItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> invoiceId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<int> lineNumber = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String> productCode = const Value.absent(),
            Value<String> company = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> quantity = const Value.absent(),
            Value<String> pricingMode = const Value.absent(),
            Value<String> enteredUnitPrice = const Value.absent(),
            Value<String> unitPriceExclTax = const Value.absent(),
            Value<String> unitPriceInclTax = const Value.absent(),
            Value<String> gstRate = const Value.absent(),
            Value<String> cgstRate = const Value.absent(),
            Value<String> sgstRate = const Value.absent(),
            Value<String> igstRate = const Value.absent(),
            Value<String> discountPercent = const Value.absent(),
            Value<String> discountAmount = const Value.absent(),
            Value<String> taxableAmount = const Value.absent(),
            Value<String> gstAmount = const Value.absent(),
            Value<String> cgstAmount = const Value.absent(),
            Value<String> sgstAmount = const Value.absent(),
            Value<String> igstAmount = const Value.absent(),
            Value<String> lineTotal = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvoiceItemsCompanion(
            id: id,
            invoiceId: invoiceId,
            productId: productId,
            lineNumber: lineNumber,
            productName: productName,
            productCode: productCode,
            company: company,
            category: category,
            quantity: quantity,
            pricingMode: pricingMode,
            enteredUnitPrice: enteredUnitPrice,
            unitPriceExclTax: unitPriceExclTax,
            unitPriceInclTax: unitPriceInclTax,
            gstRate: gstRate,
            cgstRate: cgstRate,
            sgstRate: sgstRate,
            igstRate: igstRate,
            discountPercent: discountPercent,
            discountAmount: discountAmount,
            taxableAmount: taxableAmount,
            gstAmount: gstAmount,
            cgstAmount: cgstAmount,
            sgstAmount: sgstAmount,
            igstAmount: igstAmount,
            lineTotal: lineTotal,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String invoiceId,
            required String productId,
            required int lineNumber,
            required String productName,
            required String productCode,
            required String company,
            required String category,
            required String quantity,
            required String pricingMode,
            required String enteredUnitPrice,
            required String unitPriceExclTax,
            required String unitPriceInclTax,
            required String gstRate,
            required String cgstRate,
            required String sgstRate,
            required String igstRate,
            required String discountPercent,
            required String discountAmount,
            required String taxableAmount,
            required String gstAmount,
            required String cgstAmount,
            required String sgstAmount,
            required String igstAmount,
            required String lineTotal,
            Value<int> rowid = const Value.absent(),
          }) =>
              InvoiceItemsCompanion.insert(
            id: id,
            invoiceId: invoiceId,
            productId: productId,
            lineNumber: lineNumber,
            productName: productName,
            productCode: productCode,
            company: company,
            category: category,
            quantity: quantity,
            pricingMode: pricingMode,
            enteredUnitPrice: enteredUnitPrice,
            unitPriceExclTax: unitPriceExclTax,
            unitPriceInclTax: unitPriceInclTax,
            gstRate: gstRate,
            cgstRate: cgstRate,
            sgstRate: sgstRate,
            igstRate: igstRate,
            discountPercent: discountPercent,
            discountAmount: discountAmount,
            taxableAmount: taxableAmount,
            gstAmount: gstAmount,
            cgstAmount: cgstAmount,
            sgstAmount: sgstAmount,
            igstAmount: igstAmount,
            lineTotal: lineTotal,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$InvoiceItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({invoiceId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (invoiceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.invoiceId,
                    referencedTable:
                        $$InvoiceItemsTableReferences._invoiceIdTable(db),
                    referencedColumn:
                        $$InvoiceItemsTableReferences._invoiceIdTable(db).id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$InvoiceItemsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$InvoiceItemsTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$InvoiceItemsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $InvoiceItemsTable,
    InvoiceItem,
    $$InvoiceItemsTableFilterComposer,
    $$InvoiceItemsTableOrderingComposer,
    $$InvoiceItemsTableAnnotationComposer,
    $$InvoiceItemsTableCreateCompanionBuilder,
    $$InvoiceItemsTableUpdateCompanionBuilder,
    (InvoiceItem, $$InvoiceItemsTableReferences),
    InvoiceItem,
    PrefetchHooks Function({bool invoiceId, bool productId})>;
typedef $$LocalSessionsTableCreateCompanionBuilder = LocalSessionsCompanion
    Function({
  required String id,
  required String localUserId,
  required String sessionTokenHash,
  required String refreshTokenHash,
  required String createdAt,
  Value<String?> expiresAt,
  Value<int> rowid,
});
typedef $$LocalSessionsTableUpdateCompanionBuilder = LocalSessionsCompanion
    Function({
  Value<String> id,
  Value<String> localUserId,
  Value<String> sessionTokenHash,
  Value<String> refreshTokenHash,
  Value<String> createdAt,
  Value<String?> expiresAt,
  Value<int> rowid,
});

final class $$LocalSessionsTableReferences
    extends BaseReferences<_$LocalDatabase, $LocalSessionsTable, LocalSession> {
  $$LocalSessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalUsersTable _localUserIdTable(_$LocalDatabase db) =>
      db.localUsers.createAlias(
          $_aliasNameGenerator(db.localSessions.localUserId, db.localUsers.id));

  $$LocalUsersTableProcessedTableManager get localUserId {
    final $_column = $_itemColumn<String>('local_user_id')!;

    final manager = $$LocalUsersTableTableManager($_db, $_db.localUsers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LocalSessionsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalSessionsTable> {
  $$LocalSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionTokenHash => $composableBuilder(
      column: $table.sessionTokenHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refreshTokenHash => $composableBuilder(
      column: $table.refreshTokenHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  $$LocalUsersTableFilterComposer get localUserId {
    final $$LocalUsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.localUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableFilterComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalSessionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalSessionsTable> {
  $$LocalSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionTokenHash => $composableBuilder(
      column: $table.sessionTokenHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refreshTokenHash => $composableBuilder(
      column: $table.refreshTokenHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  $$LocalUsersTableOrderingComposer get localUserId {
    final $$LocalUsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.localUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableOrderingComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalSessionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalSessionsTable> {
  $$LocalSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionTokenHash => $composableBuilder(
      column: $table.sessionTokenHash, builder: (column) => column);

  GeneratedColumn<String> get refreshTokenHash => $composableBuilder(
      column: $table.refreshTokenHash, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  $$LocalUsersTableAnnotationComposer get localUserId {
    final $$LocalUsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.localUserId,
        referencedTable: $db.localUsers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalUsersTableAnnotationComposer(
              $db: $db,
              $table: $db.localUsers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LocalSessionsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalSessionsTable,
    LocalSession,
    $$LocalSessionsTableFilterComposer,
    $$LocalSessionsTableOrderingComposer,
    $$LocalSessionsTableAnnotationComposer,
    $$LocalSessionsTableCreateCompanionBuilder,
    $$LocalSessionsTableUpdateCompanionBuilder,
    (LocalSession, $$LocalSessionsTableReferences),
    LocalSession,
    PrefetchHooks Function({bool localUserId})> {
  $$LocalSessionsTableTableManager(
      _$LocalDatabase db, $LocalSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> localUserId = const Value.absent(),
            Value<String> sessionTokenHash = const Value.absent(),
            Value<String> refreshTokenHash = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String?> expiresAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSessionsCompanion(
            id: id,
            localUserId: localUserId,
            sessionTokenHash: sessionTokenHash,
            refreshTokenHash: refreshTokenHash,
            createdAt: createdAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String localUserId,
            required String sessionTokenHash,
            required String refreshTokenHash,
            required String createdAt,
            Value<String?> expiresAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSessionsCompanion.insert(
            id: id,
            localUserId: localUserId,
            sessionTokenHash: sessionTokenHash,
            refreshTokenHash: refreshTokenHash,
            createdAt: createdAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LocalSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({localUserId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (localUserId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.localUserId,
                    referencedTable:
                        $$LocalSessionsTableReferences._localUserIdTable(db),
                    referencedColumn:
                        $$LocalSessionsTableReferences._localUserIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LocalSessionsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $LocalSessionsTable,
    LocalSession,
    $$LocalSessionsTableFilterComposer,
    $$LocalSessionsTableOrderingComposer,
    $$LocalSessionsTableAnnotationComposer,
    $$LocalSessionsTableCreateCompanionBuilder,
    $$LocalSessionsTableUpdateCompanionBuilder,
    (LocalSession, $$LocalSessionsTableReferences),
    LocalSession,
    PrefetchHooks Function({bool localUserId})>;
typedef $$BackupEventsTableCreateCompanionBuilder = BackupEventsCompanion
    Function({
  required String id,
  required String eventType,
  required String status,
  Value<String?> filePath,
  Value<String?> message,
  required String createdAt,
  Value<int> rowid,
});
typedef $$BackupEventsTableUpdateCompanionBuilder = BackupEventsCompanion
    Function({
  Value<String> id,
  Value<String> eventType,
  Value<String> status,
  Value<String?> filePath,
  Value<String?> message,
  Value<String> createdAt,
  Value<int> rowid,
});

class $$BackupEventsTableFilterComposer
    extends Composer<_$LocalDatabase, $BackupEventsTable> {
  $$BackupEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$BackupEventsTableOrderingComposer
    extends Composer<_$LocalDatabase, $BackupEventsTable> {
  $$BackupEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BackupEventsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $BackupEventsTable> {
  $$BackupEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BackupEventsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $BackupEventsTable,
    BackupEvent,
    $$BackupEventsTableFilterComposer,
    $$BackupEventsTableOrderingComposer,
    $$BackupEventsTableAnnotationComposer,
    $$BackupEventsTableCreateCompanionBuilder,
    $$BackupEventsTableUpdateCompanionBuilder,
    (
      BackupEvent,
      BaseReferences<_$LocalDatabase, $BackupEventsTable, BackupEvent>
    ),
    BackupEvent,
    PrefetchHooks Function()> {
  $$BackupEventsTableTableManager(_$LocalDatabase db, $BackupEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<String?> message = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BackupEventsCompanion(
            id: id,
            eventType: eventType,
            status: status,
            filePath: filePath,
            message: message,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String eventType,
            required String status,
            Value<String?> filePath = const Value.absent(),
            Value<String?> message = const Value.absent(),
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BackupEventsCompanion.insert(
            id: id,
            eventType: eventType,
            status: status,
            filePath: filePath,
            message: message,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BackupEventsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $BackupEventsTable,
    BackupEvent,
    $$BackupEventsTableFilterComposer,
    $$BackupEventsTableOrderingComposer,
    $$BackupEventsTableAnnotationComposer,
    $$BackupEventsTableCreateCompanionBuilder,
    $$BackupEventsTableUpdateCompanionBuilder,
    (
      BackupEvent,
      BaseReferences<_$LocalDatabase, $BackupEventsTable, BackupEvent>
    ),
    BackupEvent,
    PrefetchHooks Function()>;
typedef $$BackupSettingsTableCreateCompanionBuilder = BackupSettingsCompanion
    Function({
  required String id,
  Value<String?> backupDirectory,
  Value<bool> automaticBackupsEnabled,
  Value<String?> lastBackupAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$BackupSettingsTableUpdateCompanionBuilder = BackupSettingsCompanion
    Function({
  Value<String> id,
  Value<String?> backupDirectory,
  Value<bool> automaticBackupsEnabled,
  Value<String?> lastBackupAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$BackupSettingsTableFilterComposer
    extends Composer<_$LocalDatabase, $BackupSettingsTable> {
  $$BackupSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backupDirectory => $composableBuilder(
      column: $table.backupDirectory,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get automaticBackupsEnabled => $composableBuilder(
      column: $table.automaticBackupsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastBackupAt => $composableBuilder(
      column: $table.lastBackupAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BackupSettingsTableOrderingComposer
    extends Composer<_$LocalDatabase, $BackupSettingsTable> {
  $$BackupSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backupDirectory => $composableBuilder(
      column: $table.backupDirectory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get automaticBackupsEnabled => $composableBuilder(
      column: $table.automaticBackupsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastBackupAt => $composableBuilder(
      column: $table.lastBackupAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BackupSettingsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $BackupSettingsTable> {
  $$BackupSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get backupDirectory => $composableBuilder(
      column: $table.backupDirectory, builder: (column) => column);

  GeneratedColumn<bool> get automaticBackupsEnabled => $composableBuilder(
      column: $table.automaticBackupsEnabled, builder: (column) => column);

  GeneratedColumn<String> get lastBackupAt => $composableBuilder(
      column: $table.lastBackupAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BackupSettingsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $BackupSettingsTable,
    BackupSetting,
    $$BackupSettingsTableFilterComposer,
    $$BackupSettingsTableOrderingComposer,
    $$BackupSettingsTableAnnotationComposer,
    $$BackupSettingsTableCreateCompanionBuilder,
    $$BackupSettingsTableUpdateCompanionBuilder,
    (
      BackupSetting,
      BaseReferences<_$LocalDatabase, $BackupSettingsTable, BackupSetting>
    ),
    BackupSetting,
    PrefetchHooks Function()> {
  $$BackupSettingsTableTableManager(
      _$LocalDatabase db, $BackupSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> backupDirectory = const Value.absent(),
            Value<bool> automaticBackupsEnabled = const Value.absent(),
            Value<String?> lastBackupAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BackupSettingsCompanion(
            id: id,
            backupDirectory: backupDirectory,
            automaticBackupsEnabled: automaticBackupsEnabled,
            lastBackupAt: lastBackupAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> backupDirectory = const Value.absent(),
            Value<bool> automaticBackupsEnabled = const Value.absent(),
            Value<String?> lastBackupAt = const Value.absent(),
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BackupSettingsCompanion.insert(
            id: id,
            backupDirectory: backupDirectory,
            automaticBackupsEnabled: automaticBackupsEnabled,
            lastBackupAt: lastBackupAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BackupSettingsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $BackupSettingsTable,
    BackupSetting,
    $$BackupSettingsTableFilterComposer,
    $$BackupSettingsTableOrderingComposer,
    $$BackupSettingsTableAnnotationComposer,
    $$BackupSettingsTableCreateCompanionBuilder,
    $$BackupSettingsTableUpdateCompanionBuilder,
    (
      BackupSetting,
      BaseReferences<_$LocalDatabase, $BackupSettingsTable, BackupSetting>
    ),
    BackupSetting,
    PrefetchHooks Function()>;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$LocalUsersTableTableManager get localUsers =>
      $$LocalUsersTableTableManager(_db, _db.localUsers);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$SellersTableTableManager get sellers =>
      $$SellersTableTableManager(_db, _db.sellers);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(_db, _db.stockMovements);
  $$SellerTransactionsTableTableManager get sellerTransactions =>
      $$SellerTransactionsTableTableManager(_db, _db.sellerTransactions);
  $$CompanyProfilesTableTableManager get companyProfiles =>
      $$CompanyProfilesTableTableManager(_db, _db.companyProfiles);
  $$InvoiceItemsTableTableManager get invoiceItems =>
      $$InvoiceItemsTableTableManager(_db, _db.invoiceItems);
  $$LocalSessionsTableTableManager get localSessions =>
      $$LocalSessionsTableTableManager(_db, _db.localSessions);
  $$BackupEventsTableTableManager get backupEvents =>
      $$BackupEventsTableTableManager(_db, _db.backupEvents);
  $$BackupSettingsTableTableManager get backupSettings =>
      $$BackupSettingsTableTableManager(_db, _db.backupSettings);
}
