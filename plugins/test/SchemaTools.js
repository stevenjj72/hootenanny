
var assert = require('assert');
var st = require('../SchemaTools.js');

describe('schema', function() {
    it('implicitly pick the right to OSM tag', function() {
        assert.deepEqual(
            st.generateToOsmTable([["TYP", 1, st.simple('highway=road')]]),
            {"TYP":{"1":["highway","road"]}});

        // two consistent implicit types does not cause an error.
        assert.deepEqual(
            st.generateToOsmTable([["TYP", 1, st.simple('highway=road'),
                st.isSimilar('highway=road')]]),
            {"TYP":{"1":["highway","road"]}});

        assert.deepEqual(
            st.generateToOsmTable([["TYP", 1, "highway=road", st.simple('highway=road')]]),
            {"TYP":{"1":["highway","road"]}});

        // override with a specific type
        assert.deepEqual(
            st.generateToOsmTable([["TYP", 1, "highway=primary",
                st.simple('highway=secondary')]]),
            {"TYP":{"1":["highway","primary"]}});

        // two inconsistent implicit types should throw an error.
        assert.throws(
            function() { st.generateToOsmTable([["TYP", 1, st.simple('highway=road'),
                st.isSimilar('highway=primary')]]); },
            Error);

        // wild card doesn't implictly specify a type.
        assert.throws(function() {
            st.generateToOsmTable([["TYP", 1, st.wildcard('highway=.*')]]); },
            Error);

        // two conflicting implict types.
        assert.throws(
            function() { st.generateToOsmTable([["TYP", 1,
                st.simple('highway=primary'),
                st.isSimilar('highway=secondary')]]); },
            Error);

    });

    it('only allow unique OGR rows in to OSM', function() {
        assert.throws(
            function() { st.generateToOsmTable([
                ["TYP", 1, st.simple('highway=road')],
                ["TYP", 1, st.simple('highway=primary')]
            ]); },
            Error);
    });

    it('throws an error on bad tags', function() {
        assert.throws(
            function() { st.generateToOsmTable([["TYP", 1, st.simple('invalidkey=foo')]]); },
            Error);

        assert.throws(
            function() { st.generateToOsmTable([["TYP", 1, st.isSimilar('invalidkey=foo')]]); },
            Error);

        assert.throws(
            function() { st.generateToOsmTable([["TYP", 1, st.isA('invalidkey=foo')]]); },
            Error);

        assert.throws(
            function() { st.generateToOsmTable([["TYP", 1, st.wildcard('invalidkey=.*')]]); },
            Error);
    });

    it('handle aliases properly', function() {
        // should contain conference_centre and convention_centre
        assert.deepEqual(
            st.generateToOgrTable([["FFN", 579, st.isSimilar('amenity=convention_centre', .7, .1, .5)]]),
            {"amenity":{"convention_centre":["FFN",579,0.5],"conference_centre":["FFN",579,0.5],"exhibition_hall":["FFN",579,0.23333333333333345]}});

        // wildcard should match convention_centre and conference_centre
        assert.deepEqual(
            st.generateToOgrTable([["FFN", 579, st.wildcard('amenity=^con.*_centre', .7, .1, .5)]]),
            {"amenity":{"convention_centre":["FFN",579,0.7],"conference_centre":["FFN",579,0.7]}});
    });

    it('translate many OSM to many OGR should generate expected record', function() {
    
        // wildcard should match convention_centre and conference_centre
        var many2many = [
            {ogr:["commercial$TYPE1=Service", 
                  "commercial$TYPE2=Other",
                  "commercial$COMMENTS<=Fitness Center"], 
             osm:[st.isSimilar('leisure=fitness_centre', .9, .1, .5)]}];

        var rules = st.generateManyToOgrTable(many2many);

        var attrs = {};
        st.applyManyToOgrTable(rules, {"leisure": "fitness-center", "name": "foo"}, attrs);
        assert.deepEqual({"commercial$COMMENTS":"Fitness Center","commercial$TYPE1":"Service","commercial$TYPE2":"Other"}, attrs);

        var attrs = {"commercial$COMMENTS":"My comment"};
        st.applyManyToOgrTable(rules, {"leisure": "fitness-center", "name": "foo"}, attrs);
        assert.deepEqual({"commercial$COMMENTS":"My comment;Fitness Center","commercial$TYPE1":"Service","commercial$TYPE2":"Other"}, attrs);

    });

    it('translate many OSM to many OGR should work with isA rules', function() {
    
        // wildcard should match convention_centre and conference_centre
        var many2many = [
            {ogr:["commercial$TYPE1=Service", "commercial$TYPE2=Restaurant"], 
             osm:[st.isA('cuisine', .9, .1)]}];

        var rules = st.generateManyToOgrTable(many2many);
        var attrs = {};
        st.applyManyToOgrTable(rules, {"cuisine": "chicken", "name": "foo"}, attrs);
        assert.deepEqual({"commercial$TYPE1":"Service","commercial$TYPE2":"Restaurant"}, attrs);

    });

});
