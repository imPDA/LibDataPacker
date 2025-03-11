### Examples

<details>
  <summary>Common</summary>

  ```lua
  local playerStats = Field.Table(nil, {
      Field.String('displayName', 50),
      Field.Bool('someFlag'),
      Field.Number('damageDone', 14),  -- in K of damage/healing, 1 = 1K, 2^14-1 = 16383K; ~16.38M max in total
      -- Field.Number('damageTaken', 24),
      Field.Number('healingDone', 14),
  }, IGNORE_NAMES)

  local schema = Field.Table(nil, {
      Field.Array('groupStats', 12, playerStats),
      Field.Number('durationSeconds', 11),  -- 2047 seconds or ~34 minutes max
  }, IGNORE_NAMES)
  ```
![image](https://github.com/user-attachments/assets/a6ff7113-1812-4173-8b13-95c5c426ed16)

</details>

<details>
  <summary>Coordinates</summary>
    
  ```lua
  -- types
  local EXACT         = Field.Array('xy', 2, Field.Number(nil, 20))  -- from 0 to 0.999999
  local APPROXIMATE   = Field.Array('xy', 2, Field.Number(nil, 10))  -- from 0 to 0.999

  -- 35 exact coordinates or 70 approximate coordinates = 234 character long base64 string
  local schema = Field.Array(nil, amount, EXACT/APPROXIMATE)
  ```
![image](https://github.com/user-attachments/assets/b8f8bfe3-fbe8-4230-9b2d-d1272dbd65be)
![image](https://github.com/user-attachments/assets/7d7ed9ec-f2c0-499c-9d1a-52843cdc5e86)

</details>

<details>
  <summary>SuperStar</summary>
    
  ```lua
  local item = Field.Table('item', {
      Field.Number('id',          20),
      Field.Number('quality',     3),
      Field.Number('trait',       6),
      Field.Number('ench. id',    20),
  }, IGNORE_NAMES)

  local superStarDataSchema = Field.Table(nil, {
      Field.Number('alliance',        2),
      Field.Number('race',            3),
      Field.Number('class',           3),
      Field.Number('ava rank',        6),
      Field.Number('skill points',    10),
      Field.Number('level, cp',       12),

      Field.Array('skills',       12, Field.Number(nil, 20)),
      Field.Array('boons',        2,  Field.Number(nil, 4)),

      Field.Number('vampire/ww',      3),

      Field.Array('attributes',   3,  Field.Number(nil, 7)),
      Field.Array('resources',    3,  Field.Number(nil, 16)),
      Field.Array('regens',       3,  Field.Number(nil, 14)),
      Field.Array('wpd/spd',      2,  Field.Number(nil, 14)),
      Field.Array('critrate',     2,  Field.Number(nil, 15)),
      Field.Array('penetration',  2,  Field.Number(nil, 16)),
      Field.Array('resistance',   2,  Field.Number(nil, 17)),
      Field.Array('gear',         14, item),
      Field.Array('CP stars',     12, Field.Number(nil, 14)),
  }, IGNORE_NAMES)
  ```
![image](https://github.com/user-attachments/assets/d43bc9d5-0487-47b6-879c-8e09b452a9bf)

</details>

<details>
  <summary>String</summary>

  It can pack strings as well, but looking for better implementation :)
    
  ```lua
  local schema = Field.Array(nil, 5, Field.String(nil, 50)) 
  ```
![image](https://github.com/user-attachments/assets/0b91476b-de95-403f-9520-013cfe8040f8)

</details>
