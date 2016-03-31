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
 * @copyright Copyright (C) 2015, 2016 DigitalGlobe (http://www.digitalglobe.com/)
 */
#ifndef OSMAPIDB_H
#define OSMAPIDB_H

#include <hoot/core/io/ApiDb.h>

namespace hoot
{

class OsmApiDb : public ApiDb
{
public:

  OsmApiDb();

  virtual ~OsmApiDb();

  virtual void close();

  virtual bool isSupported(QUrl url);

  virtual void open(const QUrl& url);

  virtual void transaction();

  virtual void rollback();

  virtual void commit();

  virtual void deleteUser(long userId);

  /**
   * Returns a results iterator to all OSM elements for a given element type in the database.
   */
  virtual shared_ptr<QSqlQuery> selectElements(const ElementType& elementType);

  /**
   * Returns a vector with all the OSM node ID's for a given way
   */
  virtual vector<long> selectNodeIdsForWay(long wayId);

  /**
   * Returns a query results with node_id, lat, and long with all the OSM node ID's for a given way
   */
  virtual shared_ptr<QSqlQuery> selectNodesForWay(long wayId);

  /**
   * Returns a vector with all the relation members for a given relation
   */
  virtual vector<RelationData::Entry> selectMembersForRelation(long relationId);

  /**
   * Returns a results iterator to all OSM elements for a given bbox.
   */
  shared_ptr<QSqlQuery> selectBoundedElements(const long elementId, const ElementType& elementType, const QString& bbox);

  /**
    * Deletes data in the Osm Api db
    */
  void deleteData();

  QString extractTagFromRow(shared_ptr<QSqlQuery> row, const ElementType::Type Type);

  shared_ptr<QSqlQuery> selectTagsForWay(long wayId);

  shared_ptr<QSqlQuery> selectTagsForRelation(long wayId);

private:

  bool _inTransaction;

  shared_ptr<QSqlQuery> _selectElementsForMap;
  shared_ptr<QSqlQuery> _selectTagsForWay;
  shared_ptr<QSqlQuery> _selectTagsForRelation;
  shared_ptr<QSqlQuery> _selectMembersForRelation;

  void _resetQueries();

  void _init();

  QString _elementTypeToElementTableName(const ElementType& elementType) const;

  // Osm Api DB table strings
  static QString _getWayNodesTableName() { return "current_way_nodes"; }
  static QString _getRelationMembersTableName() { return "current_relation_members"; }
};

}

#endif // OSMAPIDB_H