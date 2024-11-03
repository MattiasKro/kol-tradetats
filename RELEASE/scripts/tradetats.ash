
record ItemImage
{
	string itemname;
	string gifname;
	string a;
	string b;
	string c;
	string d;
	string e;
	string f;
	string g;
	string h;
	string i;
};

int num_items(string name)
{
	item i = to_item(name);
	if(i == $item[none]) {
		return 0;
	}

	int amt = item_amount(i) + closet_amount(i) + equipped_amount(i) + storage_amount(i);
	amt += display_amount(i) + shop_amount(i);

	//Make a check for familiar equipment NOT equipped on the current familiar.
	foreach fam in $familiars[] {
		if(have_familiar(fam) && fam != my_familiar()) {
			if(i == familiar_equipped_equipment(fam)) {
				amt += 1;
			}
		}
	}

	//Thanks, Bale!
	// Turns out get_campground returns a list of the items that were used 
	// to populate your campground, so these items don't need their opened
	// equivalents spelled out in av-snapshot-mritems.txt.
	if(get_campground() contains i) amt += 1;
	return amt;
}

ItemImage [int] TATTOOS;

// Thanks for the helper functions Veracity!
buffer pnum_helper( buffer b, int n, int level )
{
  if ( n >= 10 )
  {
    pnum_helper( b, n / 10, level + 1 );
  }
  b.append( to_string( n % 10 ) );
  if ( level > 0 && level % 3 == 0 )
  {
    b.append( "," );
  }
  return b;
}

buffer pnum( buffer b, int n )
{
  if ( n < 0 )
  {
    b.append( "-" );
    n = -n;
  }
  return pnum_helper( b, n, 0 );
}

string pnum( int n )
{
  buffer b;
  return pnum( b, n ).to_string();
}

// Lots of stuff blatantly stolen from av-snapshot
boolean load_current_map(string fname, ItemImage[int] map)
{
	file_to_map(fname+".txt", map);
	return true;
}

boolean is_empty(string it)
{
	return ((it == "-") || (it == "") || (it == "none"));
}

ItemImage [int] getTattooOutfits(ItemImage [int] tats)
{
    ItemImage [int] result;
    foreach key, val in tats
    {
        if (!is_empty(val.a)) {
            result[key] = val;        
        }
    }
    return result;
}

string getOutfitItem(ItemImage mritem, int offset)
{
	switch(offset)
	{
        case 0:	return mritem.a;
        case 1:	return mritem.b;
        case 2:	return mritem.c;
        case 3:	return mritem.d;
        case 4:	return mritem.e;
        case 5:	return mritem.f;
        case 6:	return mritem.g;
        case 7:	return mritem.h;
        case 8:	return mritem.i;
	}
	// This is an error situation, but I guess we will just try to be graceful about it
	return "None";
}

boolean isTradeableX(ItemImage im) {
    // Start by only checking one
    if (is_empty(im.a)) return false;
    item it = to_item(im.a);
    if ((!is_tradeable(it)) || (!it.tradeable)) {
        print("Untradeable: " + im.a + " (" + mall_price(it) + ")");
        return false;
    }
    return true;
}

boolean isTradeable(ItemImage im) {
    if (is_empty(im.a)) return false;
    if (!(is_tradeable(to_item(im.a)))) return false;
    for n from 1 to 8 {
        string i = getOutfitItem(im, n);
        if (is_empty(i)) return true;
        if (!(is_tradeable(to_item(i)))) {
            print("&nbsp;- Untradeable: " + i + " (" + mall_price(to_item(i)) + ")");
            return false;
        }
    }
    return true;
}

boolean checkSanity(ItemImage im)
{
    if (is_empty(im.a)) return false;
    boolean tradeable = true;
    if (!(is_tradeable(to_item(im.a)))) 
    {
        tradeable = false;
    }
    for n from 1 to 8 {
        string i = getOutfitItem(im, n);
        if (is_empty(i)) return true;
        if (is_tradeable(to_item(i)) != tradeable) {
            print("&nbsp;- Outfit is not consistent: " + im.itemname, "purple");
            return false;
        }
    }
    return true;
}

int marketValue(ItemImage im)
{
    int value = 0;
    for n from 1 to 8 {
        string i = getOutfitItem(im, n);
        if (!is_empty(i)) 
        {
            item oneItem = to_item(i);
            value += to_int(mall_price( oneItem ));
        }
    }
    return value;
}

ItemImage [int] getTattoosWithTradeableOutfits(ItemImage [int] tats)
{
    ItemImage [int] result;
    foreach key, val in tats
    {   
        if (isTradeable(val)) {
            result[key] = val;        
        }
//        checkSanity(val);
    }
    return result;
}

boolean hasTattoo(string html, ItemImage tattoo)
{
	if(last_index_of(html, "/"+ tattoo.gifname +".gif") > 0) {
		# If user has the tattoo, we're done
		return true;
	} 
    return false;
}

boolean hasOutfit(ItemImage tattoo) 
{
    for n from 1 to 8 
    {
        string piece = getOutfitItem(tattoo, n);
        if (is_empty(piece)) return true;
        if (num_items(piece) == 0 ) return false;
    }
    return true;
}

load_current_map("av-snapshot-tattoos", TATTOOS);

//print("Total tattoos: " + TATTOOS.count());

ItemImage [int] allOutfits = getTattooOutfits(TATTOOS);
//print("Total tattoos from outfits: " + allOutfits.count());

ItemImage [int] allTradeable = getTattoosWithTradeableOutfits(allOutfits);
print("Total tattoos from tradeable outfits: " + allTradeable.count());

sort allTradeable by (to_upper_case(value.itemname));
string tattooHtml = visit_url("account_tattoos.php");

foreach key, t in allTradeable
{
    boolean hasTat = hasTattoo(tattooHtml, t);
    boolean hasStuff = hasOutfit(t);
    if (hasTat && hasStuff) print("* " + t.itemname, "green");
    else if (hasTat) print("o " + t.itemname, "black"); 
    else if (hasStuff) print("# " + t.itemname, "blue"); 
    else print("x " + t.itemname, "red"); 
}

// Just to get market value
/*
foreach key, t in allTradeable
{
    print(t.itemname + ": " + pnum(marketValue(t)));
}
*/
