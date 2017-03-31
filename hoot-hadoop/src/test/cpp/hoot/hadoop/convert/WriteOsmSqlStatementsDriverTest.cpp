/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

// Pretty Pipes
#include <pp/Hdfs.h>
#include <pp/mapreduce/Job.h>
using namespace pp;

// Qt
#include <QDir>

#include <hoot/core/TestUtils.h>
#include <hoot/hadoop/convert/WriteOsmSqlStatementsDriver.h>
#include <hoot/core/io/OsmApiDbReader.h>
#include <hoot/core/io/ServicesDbTestUtils.h>
#include <hoot/core/util/DbUtils.h>

#include "../MapReduceTestFixture.h"

namespace hoot
{

class WriteOsmSqlStatementsDriverTest : public MapReduceTestFixture
{
  CPPUNIT_TEST_SUITE(WriteOsmSqlStatementsDriverTest);
  CPPUNIT_TEST(testSqlFileOutput);
  CPPUNIT_TEST(testDatabaseOutputUsingSqlFile);
  CPPUNIT_TEST_SUITE_END();

public:

  void verifyDatabaseOutput()
  {
    OsmApiDbReader reader;
    OsmMapPtr map(new OsmMap());
    reader.open(ServicesDbTestUtils::getOsmApiDbUrl().toString());
    reader.read(map);

    //we're already validating the sql output file, so just basic db row count validation here

    //verify current elements
    CPPUNIT_ASSERT_EQUAL((size_t)117, map->getNodes().size());
    CPPUNIT_ASSERT_EQUAL((size_t)14, map->getWays().size());
    CPPUNIT_ASSERT_EQUAL((size_t)0, map->getRelations().size());

    CPPUNIT_ASSERT_EQUAL(
      (long)38,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getCurrentNodeTagsTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)39,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getCurrentWayTagsTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)121,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getCurrentWayNodesTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)0,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getCurrentRelationTagsTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)0,
      DbUtils::getRowCount(reader._getDatabase()->getDB(),
      ApiDb::getCurrentRelationMembersTableName()));

    //verify historical element table sizes
    CPPUNIT_ASSERT_EQUAL(
      (long)117,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getNodesTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)38,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getNodeTagsTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)14,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getWaysTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)39,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getWayTagsTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)121,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getWayNodesTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)0,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getRelationsTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)0,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getRelationTagsTableName()));
    CPPUNIT_ASSERT_EQUAL(
      (long)0,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getRelationMembersTableName()));

    //verify changeset table size
    CPPUNIT_ASSERT_EQUAL(
      (long)1,
      DbUtils::getRowCount(reader._getDatabase()->getDB(), ApiDb::getChangesetsTableName()));

    //verify sequences - sequences can't be updated b/c of a chicken egg situation with nextval; sql
    //file validation will have to be good enough
//    shared_ptr<OsmApiDb> osmApiDb = dynamic_pointer_cast<OsmApiDb>(reader._getDatabase());
//    CPPUNIT_ASSERT_EQUAL((long)118, osmApiDb->getNextId(ElementType::Node));
//    CPPUNIT_ASSERT_EQUAL((long)15, osmApiDb->getNextId(ElementType::Way));
//    CPPUNIT_ASSERT_EQUAL((long)1, osmApiDb->getNextId(ElementType::Relation));
//    CPPUNIT_ASSERT_EQUAL((long)2, osmApiDb->getNextId(ApiDb::getChangesetsTableName()));

    reader.close();
  }

  void init(const string& outDir, const QString outFile)
  {
    if (QFile::exists(outFile))
    {
      QFile::remove(outFile);
    }
    Hdfs fs;
    if (fs.exists(outDir))
    {
      fs.deletePath(outDir, true);
    }
    QDir().mkpath(QString::fromStdString(outDir));
    fs.copyFromLocal(
      /*"test-files/DcGisRoads.pbf"*/
      "test-files/conflate/unified/AllDataTypesA.osm.pbf",
      outDir + "/input.osm.pbf");

    //init db
    ServicesDbTestUtils::deleteDataFromOsmApiTestDatabase();
    ServicesDbTestUtils::execOsmApiDbSqlTestScript("users.sql");
  }

  void testSqlFileOutput()
  {
    const string outDir =
      "test-output/hadoop/convert/WriteOsmSqlStatementsDriverTest-testSqlFileOutput";
    const QString outFile = QString::fromStdString(outDir) + "/output.sql";
    init(outDir, outFile);

    WriteOsmSqlStatementsDriver driver;
    driver.setWriteBufferSize(10);
    driver.write(QString::fromStdString(outDir) + "/input.osm.pbf", outFile);

    TestUtils::verifyStdMatchesOutputIgnoreDate(
      "test-files/hadoop/convert/WriteOsmSqlStatementsDriverTest/output.sql", outFile);

    ServicesDbTestUtils::verifyTestDatabaseEmpty();
  }

  void testDatabaseOutputUsingSqlFile()
  {
    const string outDir =
      "test-output/hadoop/convert/WriteOsmSqlStatementsDriverTest-testDatabaseOutputUsingSqlFile";
    const QString outFile = QString::fromStdString(outDir) + "/output.sql";
    init(outDir, outFile);

    WriteOsmSqlStatementsDriver driver;
    driver.setWriteBufferSize(10);
    driver.write(QString::fromStdString(outDir) + "/input.osm.pbf", outFile);

    TestUtils::verifyStdMatchesOutputIgnoreDate(
      "test-files/hadoop/convert/WriteOsmSqlStatementsDriverTest/output.sql", outFile);

    //even though only sql file output was specified, we're still going to try to write this
    //to a db to see that its valid for now
    OsmApiDb database;
    try
    {
      database.open(ServicesDbTestUtils::getOsmApiDbUrl().toString());
      //We have to turn off constraints before writing the sql file to the db, since the table
      //copy commands are out of order and will violate ref integrity.
      //TODO: make enabling/disabling constraints using psql an option of the driver and
      //OsmApiDbBulkWriter
      database.disableConstraints();

      //write the sql file
      ApiDb::execSqlFile(ServicesDbTestUtils::getOsmApiDbUrl().toString(), outFile);

      //now re-enable the constraints to make sure the db is valid before reading from it
      database.enableConstraints();
      database.close();
    }
    catch (const HootException& e)
    {
      database.enableConstraints();
      database.close();
      throw e;
    }

    verifyDatabaseOutput();
  }
};

}

CPPUNIT_TEST_SUITE_NAMED_REGISTRATION(hoot::WriteOsmSqlStatementsDriverTest, "glacial");

