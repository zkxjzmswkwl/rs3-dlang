module jagex.item;

import slf4d;
import std.algorithm;
import std.string;
import std.stdio;
import std.array;
import std.conv : to;
import util;
import etc.c.curl;
import std.net.curl;
import std.regex;

class Item {
    private int id;
    private string name;
    private bool tradeable;
    private ulong marketValue;

    this(int id) {
        this.id = id;
    }

    // TODO: Define structure for full API response so we can marshal instead of splitting shit.
    // TODO: Caching system so we don't spam ge api.
    public void resolve() {
        try {
            auto url = "https://secure.runescape.com/m=itemdb_rs/api/catalogue/detail.json?item=" ~ this.id.to!string;
            auto http = HTTP();
            http.handle.set(CurlOption.ssl_verifypeer, 0);
            string content = std.net.curl.get(url, http).to!string;
            // If the item is > 1,000, the API returns a string with a comma in it.
            // If it's < 1,000, the API returns an int.
            // Thanks Jagex, very cool!
            // But wait, there's more. The API can also return "price": "16.3k". Comical.
            auto priceStr = content.split("\"price\":")[1].split("}")[0];
            priceStr = priceStr.replace(",", "");
            priceStr = priceStr.replace("\"", "");

            // This doesn't currently support prices of >= 1m. Too annoyed to do it atm.
            if (canFind(priceStr, "k")) {
                priceStr = priceStr.replace("k", "");
                auto thousands = priceStr[0..indexOf(priceStr, ".")].to!uint * 1000;
                auto hundreds = priceStr.split(".")[1].to!uint;
                this.marketValue = thousands + hundreds;
            } else {
                this.marketValue = priceStr.to!ulong;
            }

            this.name = content.split("\"name\":")[1].split(",")[0];
        } catch (Exception ex) {
            warn(ex.msg);
        }
    }

    public int getId() {
        return this.id;
    }

    public string getName() {
        return this.name;
    }

    public ulong getMarketValue() {
        return this.marketValue;
    }
}

///
/// As it stands in memory
///
class ItemStack {
    private Item item;
    private uint amount;

    this(Item item, uint amount) {
        this.item = item;
        this.amount = amount;
    }

    public Item getItem() {
        return this.item;
    }

    public uint getAmount() {
        return this.amount;
    }
}

/** 
{
    "item": {
        "icon": "https://secure.runescape.com/m=itemdb_rs/1725877005023_obj_sprite.gif?id=1521",
        "icon_large": "https://secure.runescape.com/m=itemdb_rs/1725877005023_obj_big.gif?id=1521",
        "id": 1521,
        "type": "Woodcutting product",
        "typeIcon": "https://www.runescape.com/img/categories/Woodcutting product",
        "name": "Oak logs",
        "description": "Logs cut from an oak tree. Used in Firemaking (15), Fletching (20).",
        "current": {
            "trend": "neutral",
            "price": "1,139"
        },
        "today": {
            "trend": "negative",
            "price": "- 5"
        },
        "members": "false",
        "day30": {
            "trend": "positive",
            "change": "+17.0%"
        },
        "day90": {
            "trend": "positive",
            "change": "+9.0%"
        },
        "day180": {
            "trend": "positive",
            "change": "+17.0%"
        }
    }
}
 */
