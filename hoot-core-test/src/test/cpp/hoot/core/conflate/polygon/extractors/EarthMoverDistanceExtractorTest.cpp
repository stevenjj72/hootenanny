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
 * @copyright Copyright (C) 2013, 2014 DigitalGlobe (http://www.digitalglobe.com/)
 */

// Hoot
#include <hoot/core/MapProjector.h>
#include <hoot/core/OsmMap.h>
#include <hoot/core/conflate/polygon/extractors/EarthMoverDistanceExtractor.h>
#include <hoot/core/elements/Way.h>
#include <hoot/core/io/OsmReader.h>
#include <hoot/core/io/OsmWriter.h>
using namespace hoot;

// CPP Unit
#include <cppunit/extensions/HelperMacros.h>
#include <cppunit/extensions/TestFactoryRegistry.h>
#include <cppunit/TestAssert.h>
#include <cppunit/TestFixture.h>

// Qt
#include <QDebug>
#include <QDir>
#include <QBuffer>
#include <QByteArray>

// Tgs
#include <tgs/StreamUtils.h>

#include "../../../TestUtils.h"

namespace hoot
{

class EarthMoverDistanceExtractorTest : public CppUnit::TestFixture
{
  CPPUNIT_TEST_SUITE(EarthMoverDistanceExtractorTest);
  CPPUNIT_TEST(runBuildingsSameTest);
  CPPUNIT_TEST(runBuildingsMostOverlapTest);
  CPPUNIT_TEST(runBuildingsSmallOverlapTest);
  CPPUNIT_TEST(runBuildingsSeparateTest);
  CPPUNIT_TEST_SUITE_END();

public:

  void setUp()
  {
    TestUtils::resetEnvironment();
  }

  void runBuildingsSameTest()
  {
    OsmReader reader;

    OsmMap::resetCounters();
    shared_ptr<OsmMap> map(new OsmMap());
    reader.setDefaultStatus(Status::Unknown1);
    reader.read("test-files/conflate/polygon/extractors/TestA.osm", map);

    //Two geometries are same
    reader.setDefaultStatus(Status::Unknown2);
    reader.read("test-files/conflate/polygon/extractors/TestB.osm", map);

    MapProjector::projectToPlanar(map);

    vector<long> r1 = map->findWays("REF1", "Target");
    vector<long> r2 = map->findWays("name", "Target Grocery");

    shared_ptr<const Way> w1 = map->getWay(r1[0]);
    shared_ptr<const Way> w2 = map->getWay(r2[0]);

    EarthMoverDistanceExtractor earthMoverDistanceExtractor;
    double emd = earthMoverDistanceExtractor.extract(*map, w1, w1);
    CPPUNIT_ASSERT_DOUBLES_EQUAL(0.0, emd, 0.01);
  }

  void runBuildingsMostOverlapTest()
  {
    OsmReader reader;

    OsmMap::resetCounters();
    shared_ptr<OsmMap> map(new OsmMap());
    reader.setDefaultStatus(Status::Unknown1);
    reader.read("test-files/conflate/polygon/extractors/TestA.osm", map);

    //Two geometries are same
    reader.setDefaultStatus(Status::Unknown2);
    reader.read("test-files/conflate/polygon/extractors/TestC.osm", map);

    MapProjector::projectToPlanar(map);

    vector<long> r1 = map->findWays("REF1", "Target");
    vector<long> r2 = map->findWays("name", "Target Grocery");

    shared_ptr<const Way> w1 = map->getWay(r1[0]);
    shared_ptr<const Way> w2 = map->getWay(r2[0]);

    EarthMoverDistanceExtractor earthMoverDistanceExtractor;
    double emd = earthMoverDistanceExtractor.extract(*map, w1, w1);
    CPPUNIT_ASSERT_DOUBLES_EQUAL(0.0, emd, 0.01);
  }

  void runBuildingsSmallOverlapTest()
  {
    OsmReader reader;

    OsmMap::resetCounters();
    shared_ptr<OsmMap> map(new OsmMap());
    reader.setDefaultStatus(Status::Unknown1);
    reader.read("test-files/conflate/polygon/extractors/TestA.osm", map);

    //Two geometries are same
    reader.setDefaultStatus(Status::Unknown2);
    reader.read("test-files/conflate/polygon/extractors/TestD.osm", map);

    MapProjector::projectToPlanar(map);

    vector<long> r1 = map->findWays("REF1", "Target");
    vector<long> r2 = map->findWays("name", "Target Grocery");

    shared_ptr<const Way> w1 = map->getWay(r1[0]);
    shared_ptr<const Way> w2 = map->getWay(r2[0]);

    EarthMoverDistanceExtractor earthMoverDistanceExtractor;
    double emd = earthMoverDistanceExtractor.extract(*map, w1, w1);
    CPPUNIT_ASSERT_DOUBLES_EQUAL(0.0, emd, 0.01);
  }

  void runBuildingsSeparateTest()
  {
    OsmReader reader;

    OsmMap::resetCounters();
    shared_ptr<OsmMap> map(new OsmMap());
    reader.setDefaultStatus(Status::Unknown1);
    reader.read("test-files/conflate/polygon/extractors/TestA.osm", map);

    //Two geometries are same
    reader.setDefaultStatus(Status::Unknown2);
    reader.read("test-files/conflate/polygon/extractors/TestE.osm", map);

    MapProjector::projectToPlanar(map);

    vector<long> r1 = map->findWays("REF1", "Target");
    vector<long> r2 = map->findWays("name", "Target Grocery");

    shared_ptr<const Way> w1 = map->getWay(r1[0]);
    shared_ptr<const Way> w2 = map->getWay(r2[0]);

    EarthMoverDistanceExtractor earthMoverDistanceExtractor;
    double emd = earthMoverDistanceExtractor.extract(*map, w1, w1);

    CPPUNIT_ASSERT_DOUBLES_EQUAL(0.0, emd, 0.01);
  }
};

CPPUNIT_TEST_SUITE_NAMED_REGISTRATION(EarthMoverDistanceExtractorTest, "quick");

}
