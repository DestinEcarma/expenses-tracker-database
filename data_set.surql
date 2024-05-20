-- ------------------------------
-- OPTION
-- ------------------------------

OPTION IMPORT;

-- ------------------------------
-- FUNCTIONS
-- ------------------------------

DEFINE FUNCTION fn::add_category($user_id: record<user>, $name: string, $icon: string) {
LET $category = (CREATE ONLY category SET name = $name, icon = $icon);
RELATE $user_id -> user_category -> ($category.id);
RETURN { id: $category.id };
} PERMISSIONS FULL;
DEFINE FUNCTION fn::add_transation($category_id: record<category>, $amount: float, $description: string) {
LET $transaction = (CREATE ONLY transaction SET amount = $amount, description = $description);
RELATE $category_id -> category_transaction -> ($transaction.id);
RETURN { id: $transaction.id };
} PERMISSIONS FULL;
DEFINE FUNCTION fn::category_ownership($user_id: record<user>, $category_id: record<category>) { RETURN array::any((SELECT id FROM $user_id->user_category WHERE out = $category_id)); } PERMISSIONS FULL;
DEFINE FUNCTION fn::transaction_ownership($category_id: record<category>, $transaction_id: record<transaction>) { RETURN array::any((SELECT id FROM $category_id->user_category WHERE out = $transaction_id)); } PERMISSIONS FULL;

-- ------------------------------
-- TABLE: category
-- ------------------------------

DEFINE TABLE category TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD created_at ON category TYPE datetime DEFAULT time::now() PERMISSIONS FULL;
DEFINE FIELD icon ON category TYPE string PERMISSIONS FULL;
DEFINE FIELD name ON category TYPE string PERMISSIONS FULL;
DEFINE FIELD updated_at ON category TYPE datetime DEFAULT time::now() PERMISSIONS FULL;

DEFINE EVENT category_deleted ON category WHEN ($event = 'DELETE') THEN {
DELETE $value.id<-user_category;
DELETE $value.id->category_transaction;
};
DEFINE EVENT category_updated ON category WHEN ($event = 'UPDATE' AND $before.updated_at == $after.updated_at) THEN { UPDATE $value.id SET updated_at = time::now(); };

-- ------------------------------
-- TABLE: category_transaction
-- ------------------------------

DEFINE TABLE category_transaction TYPE RELATION IN category OUT transaction SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD in ON category_transaction TYPE record<category> PERMISSIONS FULL;
DEFINE FIELD out ON category_transaction TYPE record<transaction> PERMISSIONS FULL;

DEFINE INDEX category_transactions_index ON category_transaction FIELDS in, out UNIQUE;
DEFINE INDEX category_transactions_out ON category_transaction FIELDS out UNIQUE;

DEFINE EVENT category_transaction ON category_transaction WHEN ($event = 'DELETE') THEN { DELETE $value.out; };

-- ------------------------------
-- TABLE: transaction
-- ------------------------------

DEFINE TABLE transaction TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD amount ON transaction TYPE float PERMISSIONS FULL;
DEFINE FIELD created_at ON transaction TYPE datetime DEFAULT time::now() PERMISSIONS FULL;
DEFINE FIELD description ON transaction TYPE string PERMISSIONS FULL;

DEFINE EVENT transaction_deleted ON transaction WHEN ($event = 'DELETE') THEN { DELETE $value.id<-category_transaction; };

-- ------------------------------
-- TABLE: user
-- ------------------------------

DEFINE TABLE user TYPE NORMAL SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD created_at ON user TYPE datetime DEFAULT time::now() PERMISSIONS FULL;
DEFINE FIELD password ON user TYPE string PERMISSIONS FULL;
DEFINE FIELD updated_at ON user TYPE datetime DEFAULT time::now() PERMISSIONS FULL;
DEFINE FIELD username ON user TYPE string PERMISSIONS FULL;

DEFINE INDEX username_index ON user FIELDS username UNIQUE;

DEFINE EVENT user_deleted ON user WHEN ($event = 'DELETE') THEN { DELETE $value.id->user_category; };
DEFINE EVENT user_updated ON user WHEN ($event = 'UPDATE' AND $before.updated_at == $after.updated_at) THEN { UPDATE $value.id SET updated_at = time::now(); };

-- ------------------------------
-- TABLE: user_category
-- ------------------------------

DEFINE TABLE user_category TYPE RELATION IN user OUT category SCHEMAFULL PERMISSIONS NONE;

DEFINE FIELD in ON user_category TYPE record<user> PERMISSIONS FULL;
DEFINE FIELD out ON user_category TYPE record<category> PERMISSIONS FULL;

DEFINE INDEX user_categories_index ON user_category FIELDS in, out UNIQUE;
DEFINE INDEX user_categories_out ON user_category FIELDS out UNIQUE;

DEFINE EVENT user_category_delete ON user_category WHEN ($event = 'DELETE') THEN { DELETE $value.out; };