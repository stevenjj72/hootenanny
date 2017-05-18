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
 * @copyright Copyright (C) 2015, 2016, 2017 DigitalGlobe (http://www.digitalglobe.com/)
 */
#include "PartialOsmMapWriter.h"

#include <hoot/core/elements/Node.h>
#include <hoot/core/elements/Relation.h>
#include <hoot/core/elements/Way.h>
#include "ElementInputStream.h"

namespace hoot
{

PartialOsmMapWriter::PartialOsmMapWriter()
{
}

void PartialOsmMapWriter::write(ConstOsmMapPtr map)
{
  LOG_INFO("PartialOsmMapWriter: About to write map");
  writePartial(map);
  LOG_INFO("PartialOsmMapWriter: About to finalise");
  finalizePartial();
  LOG_INFO("PartialOsmMapWriter: About to return");
}

void PartialOsmMapWriter::writePartial(const ConstOsmMapPtr& map)
{
  LOG_INFO("PartialOsmMapWriter: writePartial Const: set NodeMap");
  const NodeMap& nm = map->getNodes();
  LOG_INFO("PartialOsmMapWriter: writePartial Const: Loop through nodes");
  for (NodeMap::const_iterator it = nm.begin(); it != nm.end(); ++it)
  {
    LOG_INFO("About to writepartial");
    writePartial(it->second);
    LOG_INFO("Back from writepartial");
  }

  LOG_INFO("PartialOsmMapWriter: writePartial Const: set WayMap");
  const WayMap& wm = map->getWays();
  LOG_INFO("PartialOsmMapWriter: writePartial Const: loop through WayMap");
  for (WayMap::const_iterator it = wm.begin(); it != wm.end(); ++it)
  {
    LOG_INFO("About to writepartial");
    writePartial(it->second);
    LOG_INFO("Back from writepartial");
  }

  LOG_INFO("PartialOsmMapWriter: writePartial Const: set relationMap");
  const RelationMap& rm = map->getRelations();
  LOG_INFO("PartialOsmMapWriter: writePartial Const: loop through relationMap");
  for (RelationMap::const_iterator it = rm.begin(); it != rm.end(); ++it)
  {
    LOG_INFO("About to writepartial");
    writePartial(it->second);
    LOG_INFO("Back from writepartial");
  }
  LOG_INFO("PartialOsmMapWriter: writePartial Const: About to return");
}

void PartialOsmMapWriter::writePartial(const OsmMapPtr& map)
{
  LOG_INFO("PartialOsmMapWriter: writePartial About to call writePartial Const");
  writePartial((const ConstOsmMapPtr)map);
  LOG_INFO("PartialOsmMapWriter: writePartial Back from writePartial Const");
}

void PartialOsmMapWriter::writePartial(const boost::shared_ptr<const Element>& e)
{
  switch (e->getElementType().getEnum())
  {
  case ElementType::Node:
    writePartial(boost::dynamic_pointer_cast<const Node>(e));
    break;
  case ElementType::Way:
    writePartial(boost::dynamic_pointer_cast<const Way>(e));
    break;
  case ElementType::Relation:
    writePartial(boost::dynamic_pointer_cast<const Relation>(e));
    break;
  default:
    throw HootException("Unexpected element type: " + e->getElementType().toString());
  }
}

void PartialOsmMapWriter::writePartial(const RelationPtr& r)
{
  writePartial((const ConstRelationPtr)r);
}

void PartialOsmMapWriter::writeElement(ElementInputStream& in)
{
  ElementPtr ele = in.readNextElement();
  writePartial(ele);
}

void PartialOsmMapWriter::writeElement(ElementPtr &element)
{
  if (element != 0)
  {
    writePartial(element);
  }
}

}
