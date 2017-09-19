#!/usr/bin/node
/*
 * This file is part of Hootenanny.
 *
 * Hootenanny is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * --------------------------------------------------------------------
 *
 * The following copyright notices are generated automatically. If you
 * have a new notice to add, please use the format:
 * " * @copyright Copyright ..."
 * This will properly maintain the copyright information. DigitalGlobe
 * copyrights will be updated automatically.
 *
 * @copyright Copyright (C) 2017 DigitalGlobe (http://www.digitalglobe.com/)
 */

/**
 * This script produces a simple output helpful when checking the validity
 * of two translation scripts used in tandem.
 */

var fs = require('fs');
var HOOT_HOME = process.env.HOOT_HOME
var hoot = require(HOOT_HOME + '/lib/HootJs');

var map = new hoot.OsmMap();
var ogr2osm = process.argv[2];
var osm2ogr = process.argv[3];
var ogrInput = process.argv[4];
var output = process.argv[5];

hoot.loadMap(map, ogrInput, false, 1);

var maxElements = 200;

var count = 0;

map.visit(function (e) {
    if (count < maxElements * 2 && hoot.OsmSchema.isPoi(e)) {
        count++;
    } else {
        new hoot.RecursiveElementRemover(e).apply(map);
    }
});


// translate from input OGR to OSM, then OSM to output OGR
// store both input and output in a each record.
var op1 = new hoot.TranslationDebugOp({"translation.debug.in.script":ogr2osm,
    "translation.debug.out.script":osm2ogr});
op1.apply(map);

// reduce the tags down to a reasonable number based on the number of unique values.
new hoot.ReduceTagsOp().apply(map);

new hoot.ReprojectToGeographicOp().apply(map);

//hoot.saveMap(map, output);

// find all the column names.
var columns = {};
map.visit(function (e) {
    var t = e.getTags().toDict();
    for (var key in t) {
        columns[key] = 1;
    }
});

columns = Object.keys(columns);
columns.sort();
hoot.log(columns);

var tsvText = columns.join("\t");

var count = 0;

map.visit(function (e) {
    if (count < maxElements) {
        var t = e.getTags().toDict();
        row = [];
        for (var i in columns) {
            var key = columns[i];
            if (key in t) {
                row.push(t[key].replace("\t", "\\t").replace("\n", "\\n"));
            } else {
                row.push('');
            }
        }

        tsvText = tsvText + "\n" + row.join("\t");
    }
    count++;
});

console.log(tsvText);

fs.writeFile(output, tsvText, function(err) {
    if (err) {
        console.log(err);
    }
});
