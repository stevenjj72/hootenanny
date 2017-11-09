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

#include <hoot/core/elements/ConstElementVisitor.h>
#include <hoot/core/io/ShapefileWriter.h>
#include <hoot/core/util/Factory.h>

// Qt
#include <QSet>

#include "ReduceTagsOp.h"

namespace hoot
{

HOOT_FACTORY_REGISTER(OsmMapOperation, ReduceTagsOp)

class UniqueValueVisitor : public ConstElementVisitor
{
public:
  UniqueValueVisitor() {}

  virtual void visit(const ConstElementPtr& e)
  {
    const Tags& tags = e->getTags();

    for (Tags::const_iterator it = tags.begin(); it != tags.end(); ++it)
    {
      _keyValues[it.key()].insert(it.value());
    }
  }

  QMultiMap<int, QString> getKeyDiversity()
  {
    QMultiMap<int, QString> result;
    for (QHash<QString, QSet<QString> >::const_iterator it = _keyValues.begin();
         it != _keyValues.end(); ++it)
    {
      result.insertMulti(it.value().size(), it.key());
    }

    return result;
  }

  QStringList getMostDiverseKeys(int count)
  {
    int c = 0;
    QStringList result;
    QMultiMap<int, QString> diversity = getKeyDiversity();
    LOG_VAR(diversity);
    QMapIterator<int, QString> it(diversity);
    it.toBack();
    while (c < count && it.hasPrevious())
    {
      it.previous();
      // don't keep columns with only one non-null value.
      if (it.key() > 1)
      {
        result << it.value();
      }
      c++;
    }

    return result;
  }

private:
  // all the unique key/value combinations
  QHash<QString, QSet<QString> > _keyValues;
};

ReduceTagsOp::ReduceTagsOp()
{
}

void ReduceTagsOp::apply(boost::shared_ptr<OsmMap>& map)
{
  UniqueValueVisitor v;

  map->visitRo(v);

  QStringList columns = v.getMostDiverseKeys(50);
  columns.sort();

  for (NodeMap::const_iterator it = map->getNodes().begin(); it != map->getNodes().end(); ++it)
  {
    QStringList extras;

    const NodePtr& n = it->second;
    const Tags& t = n->getTags();
    Tags newTags;

    foreach (QString key, t.keys())
    {
      if (columns.contains(key))
      {
        newTags[key] = t.get(key);
      }
      else
      {
        extras << key + ": " + t.get(key);
      }
    }

    if (extras.size() > 0)
    {
      extras.sort();
      newTags["otherColumns"] = extras.join("; ");
    }
    n->setTags(newTags);
  }
}

}
