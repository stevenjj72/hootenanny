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
 * @copyright Copyright (C) 2015, 2017, 2018 DigitalGlobe (http://www.digitalglobe.com/)
 */
#ifndef BUILDINGPARTMERGEOP_H
#define BUILDINGPARTMERGEOP_H

// Hoot
#include <hoot/core/ops/OsmMapOperation.h>
#include <hoot/core/io/Serializable.h>
#include <hoot/core/elements/Element.h>
#include <hoot/core/elements/OsmMap.h>

// TGS
#include <tgs/DisjointSet/DisjointSetMap.h>

namespace __gnu_cxx
{

template<>
  struct hash< boost::shared_ptr<hoot::Element> >
  {
    size_t
    operator()(const boost::shared_ptr<hoot::Element>& k) const
    { return (size_t)(k.get()); }
  };

}

namespace hoot
{

class Relation;
class OsmSchema;

/**
 * UFD Data frequently has buildings mapped out as individual parts where each part has a different
 * height. While they may represent a single building they're presented in the Shapefile as
 * individual rows.
 *
 * I would like to maintain the richness available in the data they've collected (gabled roofs,
 * heights on sections of buildings, etc). This is very applicable to the 3D mapping being done
 * in OSM. [1]
 *
 * This class implicitly merges the individual building parts into a single part. If two buildings
 * share two or more contiguous nodes and the relevant tags match then the parts will be merged
 * into a single building. In some cases this may not be desirable (think row houses in DC without
 * addresses), but it should yield reasonable results on a case by case basis.
 *
 * When multiple parts are merged the result is a building relation. All other elements are left
 * untouched.
 *
 * It is assumed that the data has been cleaned and redundent nodes and invalid ways have been
 * removed. It is also assumed that all buildings form closed polygons.
 *
 * 1. http://wiki.openstreetmap.org/wiki/OSM-3D
 */
class BuildingPartMergeOp : public OsmMapOperation, public Serializable
{
public:

  static std::string className() { return "hoot::BuildingPartMergeOp"; }

  static unsigned int logWarnCount;

  BuildingPartMergeOp();

  virtual void apply(OsmMapPtr& map);

  virtual std::string getClassName() const { return className(); }

  virtual void readObject(QDataStream& /*is*/) {}

  virtual void writeObject(QDataStream& /*os*/) const {}

  RelationPtr combineParts(const OsmMapPtr &map,
    const std::vector< boost::shared_ptr<Element> >& parts);

  virtual QString getDescription() const
  { return "Implicitly merges individual building parts into a single part"; }

private:

  /// Used to keep track of which elements make up a building.
  Tgs::DisjointSetMap< boost::shared_ptr<Element> > _ds;
  OsmMapPtr _map;
  std::set<QString> _buildingPartTagNames;

  void _addContainedWaysToGroup(const geos::geom::Geometry& g, const boost::shared_ptr<Element>& neighbor);
  void _addNeighborsToGroup(const WayPtr& w);
  void _addNeighborsToGroup(const RelationPtr& r);

  std::set<long> _calculateNeighbors(const WayPtr& w, const Tags& tags);

  void _combineParts(const std::vector< boost::shared_ptr<Element> >& parts);

  /**
   * Compares the given tags and determines if the two building parts could be part of the same
   * builds. Returns true if they could be part of the same building.
   */
  bool _compareTags(Tags t1, Tags t2);

  /**
   * Returns true if the nodes n1 and n2 appear in w in consecutive order.
   */
  bool _hasContiguousNodes(const WayPtr& w, long n1, long n2);

  /**
   * Returns true if this way is a building, or part of a building through a relation.
   */
  bool _isBuildingPart(const WayPtr& w);
  bool _isBuildingPart(const RelationPtr& r);

};

}

#endif // BUILDINGPARTMERGEOP_H
