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
 * @copyright Copyright (C) 2014, 2015, 2017, 2018 DigitalGlobe (http://www.digitalglobe.com/)
 */

// geos
#include <geos/io/WKTReader.h>
#include <geos/geom/Point.h>

// Hoot
#include <hoot/core/elements/OsmMap.h>
#include <hoot/core/TestUtils.h>
#include <hoot/core/criterion/BuildingCriterion.h>
#include <hoot/core/io/OsmJsonWriter.h>
#include <hoot/core/io/OsmXmlReader.h>
#include <hoot/core/io/OsmXmlWriter.h>
#include <hoot/core/ops/BuildingPartMergeOp.h>
#include <hoot/rnd/ops/RefRemoveOp.h>
#include <hoot/core/util/Log.h>

// TGS
#include <tgs/Statistics/Random.h>
using namespace Tgs;

namespace hoot
{

class RefRemoveOpTest : public HootTestFixture
{
  CPPUNIT_TEST_SUITE(RefRemoveOpTest);
  CPPUNIT_TEST(runToyTest);
  CPPUNIT_TEST_SUITE_END();

public:

  RefRemoveOpTest()
  {
    setResetType(ResetBasic);
  }

  void runToyTest()
  {
    OsmXmlReader reader;

    OsmMapPtr map(new OsmMap());
    reader.setDefaultStatus(Status::Unknown1);
    reader.read("test-files/ops/RefRemoveOp/Toy.osm", map);

    RefRemoveOp uut;
    uut.addCriterion(ElementCriterionPtr(new BuildingCriterion(map)));
    uut.apply(map);

    LOG_VAR(TestUtils::toQuotedString(OsmJsonWriter(5).toString(map)));

    TestUtils::mkpath("test-output/ops/RefRemoveOp/");
    OsmXmlWriter writer;
    writer.write(map, "test-output/ops/RefRemoveOp/Toy.osm");
    HOOT_FILE_EQUALS("test-files/ops/RefRemoveOp/ToyOutput.osm",
                     "test-output/ops/RefRemoveOp/Toy.osm");
  }

};

CPPUNIT_TEST_SUITE_NAMED_REGISTRATION(RefRemoveOpTest, "quick");

}


