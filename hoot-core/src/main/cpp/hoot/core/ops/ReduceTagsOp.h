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

#ifndef REDUCETAGSOP_H
#define REDUCETAGSOP_H

#include "OsmMapOperation.h"

namespace hoot
{

/**
 * Destructively reduce the number of tags by consolidating tags with few values into a single
 * tag.
 *
 * This is useful if you want to force OSM data into a tabular format such as SHP, but don't know
 * which keys are in the OSM data.
 *
 * @note This only operates on nodes.
 */
class ReduceTagsOp : public OsmMapOperation
{
public:
  static std::string className() { return "hoot::ReduceTagsOp"; }

  ReduceTagsOp();

  virtual void apply(boost::shared_ptr<OsmMap>& map);

private:
  int _maxColumns;
};

}

#endif // REDUCETAGSOP_H
