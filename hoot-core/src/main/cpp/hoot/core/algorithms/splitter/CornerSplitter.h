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
 * @copyright Copyright (C) 2017, 2018, 2019 DigitalGlobe (http://www.digitalglobe.com/)
 */

#ifndef CORNERSPLITTER_H
#define CORNERSPLITTER_H

// Hoot
#include <hoot/core/ops/OsmMapOperation.h>
#include <hoot/core/util/Configurable.h>

// Qt
#include <QMultiHash>
#include <QSet>
#include <QMap>
#include <vector>

namespace hoot
{

class OsmMap;
class Way;

/**
 * Given an OsmMap, ways are split at sharp corners. This can help when conflating data
 * that is mostly major roads with data that contains a lot of neighborhood - level data.
 *
 */
class CornerSplitter : public OsmMapOperation, Configurable
{
public:

  static std::string className() { return "hoot::CornerSplitter"; }

  CornerSplitter();

  CornerSplitter(boost::shared_ptr<OsmMap> map);

  virtual void apply(boost::shared_ptr<OsmMap>& map) override;

  static void splitCorners(boost::shared_ptr<OsmMap> map);

  void splitCorners();

  virtual QString getDescription() const override { return "Splits sharp road corners"; }
  /**
   * Set the configuration for this object.
   */
  virtual void setConfiguration(const Settings& conf) override;

private:
  /**
   * @brief _splitRoundedCorners Split rounded corners in the middle just like a non-rounded corner
   */
  void _splitRoundedCorners();
  /**
   * @brief _splitWay Split the way at the given node, using the WaySplitter, then process the results
   * @param wayId Index of way to split
   * @param nodeIdx Index of node to split at
   * @param nodeId ID of the node to split at
   */
  void _splitWay(long wayId, long nodeIdx, long nodeId);
  /** */
  boost::shared_ptr<OsmMap> _map;
  /** */
  std::vector<long> _todoWays;
  /** */
  double _cornerThreshold;
  /** */
  bool _splitRounded;
  /** */
  double _roundedThreshold;
  /** */
  int _roundedMaxNodeCount;
};

}

#endif // CORNERSPLITTER_H
