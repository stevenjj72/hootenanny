var st = require('../plugins/SchemaTools');

var isSimilar = schemaTools.isSimilar;
var isA = schemaTools.isA;
var simple = schemaTools.simple;
var wildcard = schemaTools.wildcard;

// each of these operations assigns a score to a tag and its associated outcome. Only the highest
// scoring tag is maintained in the output table.
var one2one = [
    ["TYP", 50, 'highway=road', wildcard('highway=.*_link', 1)],
    ["TYP", 1, simple('highway=road', 2), isA('highway=road', 0.001)],
    ["TYP", 41, isSimilar('highway=motorway', 0.7, 0.1, 0.5)],
    ["TYP", 33, isSimilar('highway=unclassified', 0.7, 0.1, 0.5)],
    ["FFN", 464, isSimilar('shop=car', 0.7, 0.1, 0.5)],
    ["FFN", 572, isSimilar('amenity=restaurant', 0.7, 0.1, 0.5)],
    ["FFN", 573, isSimilar('amenity=bar', 0.8, 0.1, 0.5)],
    ["FFN", 574, isSimilar('amenity=dining_hall', 0.7, 0.1, 0.5)],
    ["FFN", 578, isSimilar('amenity=banquet_hall', 0.7, 0.1, 0.5)],
    ["FFN", 579, isSimilar('amenity=convention_centre', 0.7, 0.1, 0.5)],
    ["FFN", 594, isSimilar('amenity=cinema', 0.7, 0.1, 0.5)],
    ["FFN", 643, isSimilar('amenity=bank', 0.7, 0.1, 0.5)],
    ["FFN", 752, isSimilar('shop=photo', 0.7, 0.1, 0.5)],
    ["FFN", 775, isSimilar('shop=travel_agency', 0.7, 0.1, 0.5)]
];

var toOsmTable;
var toOgrTable;

function getToOgrTable()
{
    if (!toOgrTable)
    {
        var t = schemaTools.generateToOgrTable(one2one);
        toOgrTable = t;

        console.log(t);
        // for (var k1 in t) {
        //     for (var v1 in t[k1]) {
        //         console.log(JSON.stringify([k1, v1, t[k1][v1][0], t[k1][v1][1], t[k1][v1][2]]));
        //     }
        // }
    }

    return toOgrTable;
}

//getToOgrTable();

var many2many = [
    {ogr:["commercial$TYPE1=Service", 
          "commercial$TYPE2=Other",
          "commercial$COMMENTS<=Fitness Center"], 
     osm:[isSimilar('leisure=fitness_centre', .9, .1, .5)]},

    {ogr:["commercial$TYPE1=Service",
          "commercial$TYPE2=Other",
          "commercial$COMMENTS<=Sauna"], 
     osm:[isSimilar('leisure=sauna', 0.8, .1, .5)]},



    {ogr:["government_pois$TYPE1=Civic",
          "government_pois$TYPE2=Local Government Facility",
          "government_pois$COMMENTS<=Town Hall",], 
     osm:[isSimilar('amenity=townhall', 0.8, .1, .5)]},

    {ogr:["government_pois$TYPE1=Civic",
          "government_pois$TYPE2=Local Government Facility",
          "government_pois$COMMENTS<=Village Town Hall",], 
     osm:[isSimilar('amenity=townhall', 0.8, .1, .5), simple('townhall:type=village')]},




    {ogr:["hydrology$TYPE=Well"], 
     osm:[isSimilar('man_made=water_well', 0.8, .1, .5)]},


    {ogr:["lodging$TYPE1=Transient",
          "lodging$TYPE2=Hotel"], 
     osm:[isSimilar('amenity=hotel', 0.8, .1, .5)]},

    {ogr:["lodging$TYPE1=Transient",
          "lodging$TYPE2=Resort"], 
     osm:[isSimilar('leisure=resort', 0.8, .1, .5)]},


    {ogr:["natural$TYPE=Delta"], 
     osm:[isSimilar('natural=delta', 0.8, .1, .5)]},

    {ogr:["natural$TYPE=Headland"], 
     osm:[isSimilar('natural=headland', 0.8, .1, .5)]},

    {ogr:["natural$TYPE=Inlet"], 
     osm:[isSimilar('natural=inlet', 0.8, .1, .5)]},

    {ogr:["natural$TYPE=Island"], 
     osm:[isSimilar('place=island', 0.8, .1, .5)]},

    {ogr:["natural$TYPE=Lake"], 
     osm:[isSimilar('water=lake', 0.9, .1, .5)]},

    {ogr:["natural$TYPE=Shoal"], 
     osm:[isSimilar('natural=shoal', 0.9, .1, .5)]},

    {ogr:["natural$TYPE=Spit"], 
     osm:[isSimilar('natural=spit', 0.9, .1, .5)]},


    // {ogr:["marine_infrastructure$TYPE=Channel"], 
    //  osm:[isSimilar('poi=marine_channel', 0.8, 0, 1)]},


    {ogr:["recreation$TYPE=Playground"], 
     osm:[isSimilar('leisure=playground', 0.9, .1, .5)]},

    {ogr:["recreation$TYPE=Sports Facility", 
          "recreation$COMMENTS<=Golf Course"], 
     osm:[isSimilar('leisure=golf_course', 0.8, .1, .5)]},



    {ogr:["religious_institutions$TYPE=Shrine"], 
     osm:[isSimilar('historic=wayside_shrine', 0.7, .1, .5)]},

];

//schemaTools.generateOsmRulePermutations(many2many);
var rules = schemaTools.generateManyToOgrTable(many2many);
console.log(JSON.stringify(rules, null, "    "));

var attrs = {};
schemaTools.applyManyToOgrTable(rules, {"amenity": "townhall", "name": "foo"}, attrs);
console.log(attrs);

var attrs = {};
schemaTools.applyManyToOgrTable(rules, {"error:circular":"15","leisure": "playground", "name": "foo","hoot:status":"invalid"}, attrs);
console.log(attrs);
