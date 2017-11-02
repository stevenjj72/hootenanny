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
 * @copyright Copyright (C) 2013 DigitalGlobe (http://www.digitalglobe.com/)
 */

// if (!exports)
if (typeof exports === 'undefined')
{
    exports = {};
}
schemaTools = exports;

if (typeof hoot === 'undefined')
{
    var HOOT_HOME = process.env.HOOT_HOME;
    var hoot = require(HOOT_HOME + '/lib/HootJs');

}

function standardCompare(a, b) {
    if (a < b) return -1;
    if (a > b) return 1;
    return 0;
}

schemaTools.applyManyToOgrTable = function(rulesTable, tags, attrs) {
    var matchingRules = [];
    schemaTools.applyManyToOgrTableRec(rulesTable, tags, matchingRules, []);

    var result;
    // if there is more than one matching rule, throw an appropriate error
    if (matchingRules.length > 1) {
        hoot.logWarn("More than one rule matched the specified tag set: " + JSON.stringify(tags) + " rules: " + JSON.stringify(matchingRules));
        result = false;
    // if there is a single matching rule, apply the rule and report any overlapping columns
    } else if (matchingRules.length == 1) {
        for (var key in matchingRules[0].rules) { 
            var value = matchingRules[0].rules[key];
            var contains = matchingRules[0].rules._CONTAINS_[key];
            if (contains && attrs[key] && attrs[key] != '') {
                attrs[key] = attrs[key] + ";" + value;
            } else {
                attrs[key] = value; 
            }
        }

        //hoot.logWarn(JSON.stringify(matchingRules[0].usedTags));
        for (var keyForRemoval in matchingRules[0].usedTags) {
            delete tags[matchingRules[0].usedTags[keyForRemoval]];
        }

        result = true;
    }

    //hoot.logWarn(JSON.stringify(tags));

    // return true if a rule was applied correctly.
    return result;
}

/**
 * Recursive helper for applyManyToOgrTable
 */
schemaTools.applyManyToOgrTableRec = function(rulesTable, tags, matchingRules, usedTags) {
    // create a sorted list of the tag keys
    var keys = Object.keys(tags);
    keys.sort();

    var result = false;
    if (keys.length == 0) return false;

    // pop the first key
    var firstKey = keys.shift();

    var tagsCopy = JSON.parse(JSON.stringify(tags));
    delete tagsCopy[firstKey];

    // if the first key matches, then recursively look for a matching rule.
    if (rulesTable[firstKey] && rulesTable[firstKey][tags[firstKey]]) {
        var newUsedTags = JSON.parse(JSON.stringify(usedTags));
        newUsedTags.push(firstKey);
        var remainingRules = rulesTable[firstKey][tags[firstKey]];
        if (!schemaTools.applyManyToOgrTableRec(remainingRules, tagsCopy, matchingRules, newUsedTags)) {
            //hoot.logWarn(JSON.stringify(newUsedTags));
            if (remainingRules._OGR_) {
                matchingRules.push({rules: remainingRules._OGR_, usedTags: newUsedTags});
                result = true;
            }
        }
    // if there wasn't a specific match, look for a general match
    } else if (rulesTable[firstKey] && rulesTable[firstKey]["*"]) {
        var newUsedTags = JSON.parse(JSON.stringify(usedTags));
        newUsedTags.push(firstKey);
        var remainingRules = rulesTable[firstKey]["*"];
        if (!schemaTools.applyManyToOgrTableRec(remainingRules, tagsCopy, matchingRules, newUsedTags)) {
            //hoot.logWarn(JSON.stringify(newUsedTags));
            if (remainingRules._OGR_) {
                matchingRules.push({rules: remainingRules._OGR_, usedTags: newUsedTags});
                result = true;
            }
        }
    }

    // use the remaining keys to recursively look for a matching rule.
    var recurseResult = schemaTools.applyManyToOgrTableRec(rulesTable, tagsCopy, matchingRules, usedTags);
    result = result || recurseResult;

    return result;
}

schemaTools.expandAliases = function(tags) {
    var result = [];

    for (var i in tags) {
        var t = tags[i];

        for (var j in t.aliases) {
            var newT = JSON.parse(JSON.stringify(t));
            newT.name = t.aliases[j];
            newT.key = schemaTools.splitKvp(newT.name).key;
            newT.value = schemaTools.splitKvp(newT.name).value;
            newT.aliases = [];

            result.push(newT);
        }

        t.aliases = [];

        result.push(t);
    }

    return result;
}

schemaTools.isSimilar = function(name, threshold, minScore, maxScore) {
    if (threshold === undefined) {
        threshold = 0.8;
    }
    if (minScore === undefined) {
        minScore = 1;
    }
    if (maxScore === undefined) {
        maxScore = minScore;
    }

    if (!hoot.OsmSchema.getTagVertex(name)) {
        throw new Error("Invalid tag specified in isSimilar: " + JSON.stringify(name));
    }

    return {
        "ruleType": "similarTo",
        "threshold": threshold,
        "minScore": minScore,
        "maxScore": maxScore,
        "name": name,
        "toOsmKvp": name
    };
}

/**
 * Given a list of rules, generate a new list of concrete rules (OSM to OGR) with associated 
 * scores. If there are overlapping rules, the rule with the highest score will be kept.
 * 
 * @param rules - Takes the form:
 *  [{ osm: [<rule1>, <rule2>, ...]
 *    ogr: ["<column1>=<value1>", "<column2>=<value2>", ...]
 *  }, ...]
 * Where <rule1> is generated by isSimilar, simple, wildcard, etc.
 *
 * @result
 *    {
 *      <key1>: {
 *        <value1>: {
 *          _SCORE_: <score>,
 *          _OGR_: [
 *            <col1>: <val1>,
 *            ...
 *          ]
 *        },
 *        <value2>: <...>
 *      },
 *      <...>
 *    }
 */
schemaTools.generateManyToOgrTable = function(rules) {
    // build a more efficient lookup
    var result = {};

    // generate a new rule for each possible OSM -> OGR combination. Only the highest scoring 
    // rules will persist.
    allRules = schemaTools.generateManyToOgrPermutations(rules);

    // add each permutation to the final result.
    // if the permutation has a higher score than the existing rule, replace the existing rule.
    for (var i in allRules) {
        // sort by the keys
        allRules[i].osm.sort(function(a, b) { return standardCompare(a.key, b.key); });

        var luk = result;
        var score = 0;
        // reference one key at a time till you get to the end. If there is already an entry, 
        // compare the scores and the largest score wins.
        for (var j in allRules[i].osm) {
            var entry = allRules[i].osm[j];
            score = score + entry.score;
            if (!luk[entry.key]) luk[entry.key] = {};
            if (!luk[entry.key][entry.value]) luk[entry.key][entry.value] = {};
            
            luk = luk[entry.key][entry.value];
            if (j == allRules[i].osm.length - 1) {
                if (!luk._SCORE_ || luk._SCORE_ < score) {
                    luk._SCORE_ = score;
                    luk._OGR_ = {};
                    luk._OGR_._CONTAINS_ = {};
                    for (var k in allRules[i].ogr) {
                        var kvp = schemaTools.splitKvp(allRules[i].ogr[k]);
                        luk._OGR_[kvp.key] = kvp.value;
                        if (kvp.contains) {
                            luk._OGR_._CONTAINS_[kvp.key] = 1;
                        }
                    }
                }
            }
        }
    }

    return result;
}

/**
 * Given a list of rules, generate a new list of concrete rules (OSM to OGR) with associated 
 * scores. If there are overlapping rules, the rule with the highest score will be kept.
 * 
 * @param rules - Takes the form:
 *  [{ osm: [<rule1>, <rule2>, ...]
 *    ogr: ["<column1>=<value1>", "<column2>=<value2>", ...]
 *  }, ...]
 * Where <rule1> is generated by isSimilar, simple, wildcard, etc.
 */
schemaTools.generateManyToOgrPermutations = function(rules) {
    var result = [];

    for (var row in rules)
    {
        // list of permutations for each rule. e.g.
        // [[amenity=pub, amenity=bar], [building=bar, building=restaurant]]
        var perms = [];

        for (var r in rules[row].osm) {
            var rule = rules[row].osm[r];

            var tags;
            if (rule.ruleType === 'isA') {
                tags = [];
                var candidates = hoot.OsmSchema.getChildTags(rule.name);

                // Add the parents
                candidates.push(hoot.OsmSchema.getTagVertex(rule.name));

                for (i in candidates) {
                    candidates[i].score = rule.score;
                    tags.push(candidates[i]);
                }
            } else if (rule.ruleType == "similarTo") {
                var tags = hoot.OsmSchema.getSimilarTags(rule.name, rule.threshold);
                tags = tags.map(function (t) { 
                    var schemaScore = hoot.OsmSchema.scoreOneWay(t.name, rule.name);
                    if (schemaScore >= rule.threshold)
                    {
                        // scale the score so that rule.threshold -> 0, and 1 -> 1. Linearly.
                        var score = (schemaScore - rule.threshold) / (1 - rule.threshold);
                        // scale the final score so that 0 -> minScore and 1 -> maxScore
                        t.score = (rule.maxScore - rule.minScore) * score + rule.minScore;
                    }
                    return t;
                });
            } else if (rule.ruleType == "simple") {
                var kvp = schemaTools.splitKvp(rule.name);
                if (kvp.contains) throw new Error("Contains isn't supported in OSM, yet. " + kvp);
                tags = [{name:rule.name, score:rule.score, key:kvp.key, value:kvp.value}];
            } else {
                throw new Error("Unsupported rule type: " + rule.ruleType);
            }

            tags = schemaTools.expandAliases(tags).filter(function(t) {
                return t.value !== '' && t.score;
            });
            if (tags.length === 0) {
                throw new Error("Rule didn't match any known tags: " + rule.name);
            }

            perms.push(tags);
        }

        schemaTools.makeAllPermutations(perms, [], rules[row].ogr, result);
    }

    return result;
}

/**
 * The input table is expected to be in the form:
 * [ [key1, value1, rule1], [key2, value2, rule2] ]
 * Where rules is one of the above (isA or isSimilar).
 *
 * The rules are prioritized so higher scoring rules override lower scoring rules. Duplicate records
 * will not be generated and warnings will only be produced if ogr.debug.lookupclass == true.
 *
 *
 */
schemaTools.generateRuleTags = function(rule) {
    var result = [];

    if (rule.ruleType === 'similarTo') {
        var tags = hoot.OsmSchema.getSimilarTags(rule.name, rule.threshold);

        tags = schemaTools.expandAliases(tags);

        for (i in tags) {
            if (tags[i].value !== '' && tags[i].value !== '*')
            {
                var schemaScore = hoot.OsmSchema.scoreOneWay(tags[i].name, rule.name);
                if (schemaScore >= rule.threshold)
                {
                    // scale the score so that rule.threshold -> 0, and 1 -> 1. Linearly.
                    var score = (schemaScore - rule.threshold) / (1 - rule.threshold);
                    // scale the final score so that 0 -> minScore and 1 -> maxScore
                    tags[i].score = (rule.maxScore - rule.minScore) * score + rule.minScore;
                    result.push(tags[i]);
                }
            }
        }
    } else if (rule.ruleType === 'isA') {
        var tags = hoot.OsmSchema.getChildTags(rule.name);

        // Add the parents
        tags.push.apply(tags,[hoot.OsmSchema.getTagVertex(rule.name)]);

        tags = schemaTools.expandAliases(tags);

        for (i in tags) {
            if (tags[i].value !== '' && tags[i].value !== '*')
            {
                tags[i].score = rule.score;
                result.push(tags[i]);
            }
        }
    } else if (rule.ruleType === 'simple') {
        var tags = [hoot.OsmSchema.getTagVertex(rule.name)];
        tags = schemaTools.expandAliases(tags);

        for (i in tags) {
            tags[i].score = rule.score;
            result.push(tags[i]);
        }
    } else if (rule.ruleType === 'wildcard') {
        result = result.concat(schemaTools.getWildcardTags(rule.name, rule.score));
    } else {
        throw new Error("Unexpected rule type: " + rule.ruleType);
    }


    return result;
}

/**
 * The input table is expected to be in the form:
 * [ [key1, value1, rule1], [key2, value2, rule2] ]
 * Where rules is one of the above (isA or isSimilar).
 */
schemaTools.generateToOsmTable = function(rules) {

    // build a more efficient lookup
    var lookup = {}

    for (var r in rules)
    {
        var row = rules[r];

        if (row[2]) // Make sure it isn't 'undefined'
        {
            var toOsmKvp = schemaTools.getToOsmKvp(row);

            var key = schemaTools.splitKvp(toOsmKvp).key;
            var value = schemaTools.splitKvp(toOsmKvp).value;

            if (!(row[0] in lookup))
            {
                lookup[row[0]] = {}
            }

            if (lookup[row[0]][row[1]])
            {
                throw new Error('Export Table Clash: ' + row[0] + ' ' + row[1] + '  is ' +
                    lookup[row[0]][row[1]] + '  tried to change to ' + [key, value]);
            }

            lookup[row[0]][row[1]] = [key, value];
        }
    }

    return lookup;
}

/**
 * Go through a list of fuzzy rules and create an OSM to OGR lookup table. The table takes the 
 * form:
 * 
 *  { <osm key1>: {
 *      <osm value1>: [<ogr key>, <ogr value>, <score>],
 *      <osm value2>: [<ogr key>, <ogr value>, <score>],
 *      <...>
 *      }
 *    <osm key2>: <...>
 *  }
 *
 * If a fuzzy rule matches multiple tags then only the best match is kept. Ties result in an 
 * arbitrary assignment.
 */
schemaTools.generateToOgrTable = function(rules) {

    // build a more efficient lookup
    var lookup = {}

    for (var r in rules)
    {
        var row = rules[r];

        if (row[2]) // Make sure it isn't 'undefined'
        {
            var osmValues = [];
            for (var i = 2; i < row.length; i++) {
                if (typeof row[i] != 'string') {
                    osmValues = osmValues.concat(schemaTools.generateRuleTags(row[i]));
                }
            }

            if (osmValues.length == 0) {
                throw new Error("Unable to create any rules from a row: " + JSON.stringify(row));
            }

            // go through all the specific rules that were generated.
            for (var i in osmValues) {
                var tag = osmValues[i];

                if (!(tag.key in lookup))
                {
                    lookup[tag.key] = {}
                }

                if (!(tag.value in lookup[tag.key]) ||
                    tag.score > lookup[tag.key][tag.value][2])
                {
                    lookup[tag.key][tag.value] = [row[0], row[1], tag.score];
                }
            }
        }
    }

    return lookup;
}

schemaTools.getToOsmKvp = function(row) {
    var result;

    if (typeof row[2] == 'string') {
        result = row[2];
        return result;
    }

    for (var i = 2; i < row.length; i++) {
        if (row[i].toOsmKvp) {
            if (!result) {
                result = row[i].toOsmKvp;
            } else if (result !== row[i].toOsmKvp) {
                throw new Error("Inconsistent implicit toOsm KVP in row: " + JSON.stringify(row));
            }
        }
    }

    if (!result) {
        throw new Error("No OSM KVP is specified. Try specifying it explicitly.");
    }

    return result;
}

schemaTools.getWildcardTags = function(kvp, score) {
    var result = [];
    var split = schemaTools.splitKvp(kvp);

    var keyRx = new RegExp(split.key);
    var valueRx = new RegExp(split.value);

    var allTags = hoot.OsmSchema.getAllTags();
    allTags = schemaTools.expandAliases(allTags);

    for (var i in allTags) {
        var tag = allTags[i];
        if (tag.key.search(keyRx) !== -1 &&
            tag.value.search(valueRx) !== -1)
        {
            if (score) {
                tag.score = score;
            }
            result.push(tag);
        }
    }

    return result;
}

schemaTools.isA = function(name, score) {
    if (score === undefined) {
        score = 0.001;
    }

    if (!hoot.OsmSchema.getTagVertex(name)) {
        throw new Error("Invalid tag specified in isA: " + JSON.stringify(name));
    }

    return {
        "ruleType": "isA",
        "score": score,
        "name": name,
        "toOsmKvp": name
    };
}

schemaTools.makeAllPermutations = function(perms, picked, mapTo, result) {
    if (perms.length > 0) {
        var myPerms = perms.slice(0);
        var p = myPerms.shift();
        for (var i in p) {
            var myPicked = picked.slice(0);
            myPicked.push(p[i]);
            schemaTools.makeAllPermutations(myPerms, myPicked, mapTo, result);
        }
    } else {
        result.push({osm: picked, ogr: mapTo});
    }
}

schemaTools.simple = function(name, score) {
    if (!score) {
        score = 2;
    }

    if (!hoot.OsmSchema.getTagVertex(name)) {
        throw new Error("Invalid tag specified in simple: " + JSON.stringify(name));
    }

    return {
        "ruleType": "simple",
        "score": score,
        "name": name,
        "toOsmKvp": name
    };
}

schemaTools.splitKvp = function(kvp) {
    var equalsPos = kvp.indexOf('=');
    var containsPos = kvp.indexOf('<=');

    var contains = false;
    var key, value;

    if (equalsPos == -1) {
        key = kvp;
    } else {
        if (containsPos < equalsPos && containsPos != -1) {
            key = kvp.substring(0, containsPos);
            value = kvp.substring(containsPos + 2);
            contains = true;
        } else {
            key = kvp.substring(0, equalsPos);
            value = kvp.substring(equalsPos + 1);
        }
    }

    return {key: key, value: value, contains: contains};
}

/**
 * @param name is a key=[regex] where regex uses the JavaScript syntax.
 */
schemaTools.wildcard = function(name, score) {
    if (score === undefined) {
        score = 1;
    }

    if (schemaTools.getWildcardTags(name).length === 0) {
        throw new Error("wildcard didn't match any tags: " + JSON.stringify(name));
    }

    return {
        "ruleType": "wildcard",
        "score": score,
        "name": name
    };
}

