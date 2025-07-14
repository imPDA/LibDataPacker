# LibDataPacker Documentation

LibDataPacker is a Lua library for efficiently packing and unpacking data structures into compact binary representations. It provides:
- Strongly typed schema definitions
- Efficient serialization
- Support for various data types
- Configurable bit-level precision

## 1. Field Types
<details>
<summary>Numeric</summary>

```lua
Field.Number(name, bitLength, precision)
```
- name: Field name, _optional_
- bitLength: Number of bits to use
- precision: Decimal precision, _optional_

Creates a field for storing numbers. The bitLength defines the maximum storable value as 2^bitLength - 1. For example, a numeric field with bitLength = 10 can store numbers from 0 to 1023 (since 2^10 - 1 = 1023).

The precision parameter controls number rounding:
- If omitted, the field will store integer values only
- If precision > 0: Specifies the number of decimal places to preserve
- If precision < 0: Specifies rounding strength (step size)

```lua
local n1 = Field.Number(nil, 10)     -- Integer range: 0 - 1023
local n2 = Field.Number(nil, 10, 2)  -- Decimal range: 0.00 - 10.23 (2 decimal places)
local n3 = Field.Number(nil, 10, -2) -- Scaled integer range: 0 - 102300 (steps of 100)
```

</details>

<details>
<summary>Boolean</summary>

```lua
Field.Bool(name)
```
Represents a true/false value in a single bit.
- name: Field name, _optional_

```lua
local someFlag = Field.Bool('flagName')  -- true/false
```
</details>

<details>
<summary>String</summary>

```lua
Field.String(name, maxLength)
```
- name: Field name, _optional_
- maxLength: Maximum expected string length

```lua
local name = Field.String('characterName', 25)  -- SuperCharacterNamePK
```
</details>

<details>
<summary>Enum</summary>

```lua
Field.Enum(name, enumTable, inverted)
```
- name: Field name, _optional_
- enumTable: Table mapping values to numeric IDs
- inverted: If true, table is {value = name} instead of {name = value}

Simple {name - value} table.

```lua

local enum = {
  ['one'] = 1,
  ['two'] = 2,
  ['three'] = 3,
}

local invertedEnum = {
  [1] = 'one',
  [2] = 'two',
  [3] = 'three,
}

local someEnum1 = Field.Enum(nil, enum)
local someEnum2 = Field.Enum(nil, invertedEnum, true)
```
</details>

<details>
<summary>Array</summary>

```lua
Field.Array(name, length, elementType)  -- Fixed length
```
- name: Field name, _optional_
- length: Array length
- elementType: type of array elements (can be any `Field`)
</details>

Indexed table with strictly defined amount of elements.

```lua
local id = Field.Number(nil, 20)
local array = Field.Array(nil, 5, id)  

-- array of 5 id's:
local data = {
  111111,
  222222,
  333333,
  444444,
  555555,
}
```

<details>
<summary>Variable Length Array</summary>

```lua
Field.VLArray(name, maxLength, elementType)  -- Variable length
```
- name: Field name, _optional_
- maxLength: Max expected length
- elementType: type of array elements
</details>

Same as `Array`, but can contain from `0` to `maxLength` elements.

<details>
<summary>Table/Struct</summary>

```lua
Field.Table(name, fields, ignoreNames)
fields: Array of field definitions
```
- name: Field name, _optional_
- fields: Table with type of every field
- ignoreNames: If true, uses array indices instead of field names, default `false`, _optional_

Represents table of other fields, almost always can be used as root `Field` in shemas.

```lua
local id = Field.Number(nil, 20)
local someEnum1 = Field.Enum(nil, enum)
local name = Field.String('characterName', 25)

local IGNORE_NAMES = true

local mySchema = Field.Table(nil, {
  id,
  enum,
  name,
}, IGNORE_NAMES)

-- or

local mySchema = Field.Table(nil, {
  Field.Number(nil, 20),
  Field.Enum(nil, enum),
  Field.String(nil, 25)
}, IGNORE_NAMES)

-- data example:
local someData = {
  123456,             -- id
  3,                  -- enum
  "SomeSuperNamePK",  -- name
}
```

</details>

## 2. Core Functions
### Pack Data
```lua
LibDataPacker.Pack(data, schema, base)
```
Serializes data according to schema.
- data: Input data table
- schema: Field definition
- base: Encoding base (default: Base64)

### Unpack Data
```lua
LibDataPacker.Unpack(packedData, schema, base)
```
Deserializes packed data.
- packedData: Input packed data
- schema: Field definition
- base: Encoding base (default: Base64)

## 3. Example Usage

_This is just an example to show what is possible. All values are arbitrary and can vary from real in-game values you should actually use._

Let's assume we want to save an item with an id, quality, trait, and enchantment id. That means we need 4 fields:
- **id**: number from 1 to 1M, so we should create a `Number` field with a bit length of 20 (`2^20-1 = 1,048,575`, which covers the full range 1–1M)
- **quality**: number from 1 to 6, so the bit length must be 3 (`2^3-1 = 7`)
- **trait**: number with a maximum of 54, so the closest bit length is 6 (`2^6-1 = 63`)
- **enchantment id**: number, bit length 20 (max = `1,048,575`)

The item schema itself is a `Table` field with names ignored:

```lua
local IGNORE_NAMES = true

-- Item schema
local item = Field.Table('item', {
    Field.Number('id', 20),
    Field.Number('quality', 3),
    Field.Number('trait', 6),
    Field.Number('enchantmentId', 20),
}, IGNORE_NAMES)
```

This means we must provide an indexed table to the packer like this:

```lua
local item1 = {
  [1] = 123456, -- id
  [2] = 7,      -- quality
  [3] = 8,      -- trait
  [4] = 901234  -- enchantment id
} 

-- or 

local item2 = {
  987654, -- id
  3,      -- quality
  2,      -- trait
  109876  -- enchantment id
}
```

We could set IGNORE_NAMES = false, but that would require a table with named indices (not recommended, as this type of table is slightly slower, which could impact encoding/decoding performance):

```lua
local item1 = {
  id = 123456,
  quality = 7,
  trait = 8,
  enchantmentId = 901234
} 

-- or 

local item2 = {
  ['id'] = 987654,
  ['quality'] = 3,
  ['trait'] = 2,
  ['enchantmentId'] = 109876
}
```

For the rest of this example, names will be ignored.

Next, we define a character with a name and an inventory (2 fields):
- **name**: string, max length 25 (according to ESO Help)
- **inventory**: array of items with length 20 (an array is an indexed table)

```lua
-- Character schema
local charSchema = Field.Table(nil, {
    Field.String('name', 25),
    Field.Array('inventory', 20, item),
}, IGNORE_NAMES)
```

Valid character data might look like this:

```lua
local myChar = {
  "Some name",  -- name
  {             -- inventory         
    item1,
    item2, 
    {987654, 3, 2, 109876},
    -- ... 17 more items
  }
}
```

That's all! We can now pack and unpack our data like this:

```lua
local packed = LibDataPacker.Pack(myChar, charSchema)

-- returns string in Base64 (by default), like this:
-- j32892489n2jklsoojgfj902iono2kpm23oin4jkvlksdmifiv2novx23i0n


local unpacked = LibDataPacker.Unpack(packed, charSchema)

-- returns the initial table
-- {
--   "Some name",
--   {         
--     {123456, 7, 8, 901234},
--     {987654, 3, 2, 109876}, 
--     {987654, 3, 2, 109876},
--     ... 17 more items
--   }
-- }
```

Please refer to extra/build/main.lua for more advanced example.