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
 * @copyright Copyright (C) 2015 DigitalGlobe (http://www.digitalglobe.com/)
 */
#include "AngleHistogramVisitor.h"

// geos
#include <geos/geom/LineString.h>

// hoot
#include <hoot/core/Factory.h>
#include <hoot/core/OsmMap.h>
#include <hoot/core/util/ElementConverter.h>

namespace hoot
{

void AngleHistogramVisitor::visit(const ConstElementPtr& e)
{
  if (e->getElementType() == ElementType::Way)
  {
    const ConstWayPtr& w = dynamic_pointer_cast<const Way>(e);
    //const ConstWayPtr& w = _map.getWay(e->getId());

    vector<long> nodes = w->getNodeIds();
    if (nodes[0] != nodes[nodes.size() - 1])
    {
      nodes.push_back(nodes[0]);
    }

    Coordinate last = _map.getNode(nodes[0])->toCoordinate();
    for (size_t i = 1; i < nodes.size(); i++)
    {
      Coordinate c = _map.getNode(nodes[i])->toCoordinate();
      double distance = c.distance(last);
      double theta = atan2(c.x - last.x, c.y - last.y);
      _h.addAngle(theta, distance);
      last = c;
    }
  }
}

}
