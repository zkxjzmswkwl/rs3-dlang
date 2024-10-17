### ConfigProvider/PlayerVarDomain - 937-1

`4D 8B 88 ? ? ? ? 49 81 C0`


## Highlighting etc
Can switch out colours with only memory writes. There is no need to force a reapplication of settings nor is there a check against the written colours to ensure they are within the bounds of the pre-selected palette.

![alt](https://i.imgur.com/w3akBzZ.gif)


### RVA of static silhouette colour array base
`0xB62AC4` - can be found used in all cs2 functions pertaining to silhouette highlighting, barring `set_loc/npc_show_as_important`.

### cs2 _highlight_set_category_colour 

- Takes in two pointers, `thisptr` is never used.
- Second argument is a pointer to colour structure.
- Constant `0.0039215689` is used. Multiplying this constant converts a colour value in range 1-255 into OpenGl's 0f-1f range.

`83 82 ? ? ? ? ? 4C 8B C2 44 8B 8A`

### highlight_set_loc_show_as_important
- Probably useful for QuestHelper.
- cs2 function, contains debug string.

### highlight_set_npc_show_as_important
- Ditto

### getInventory

938-1 RVA: `0x2D7360`

Signature from 938-1 binary, tested in 937-1.

`48 89 5C 24 ? 4C 8B 59 ? 44 8D 14 12`