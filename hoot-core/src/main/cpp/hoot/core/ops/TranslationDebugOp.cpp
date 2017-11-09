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

// hoot
#include <hoot/core/OsmMap.h>
#include <hoot/core/elements/ConstElementVisitor.h>
#include <hoot/core/io/ScriptToOgrTranslator.h>
#include <hoot/core/io/ScriptTranslator.h>
#include <hoot/core/io/ScriptTranslatorFactory.h>
#include <hoot/core/util/ElementConverter.h>
#include <hoot/core/util/Factory.h>

#include "TranslationDebugOp.h"

namespace hoot
{

HOOT_FACTORY_REGISTER(OsmMapOperation, TranslationDebugOp)

/**
 * Translates and add translated elements to a destination map with tags marking them up as in/out
 * values. This is a rather specific visitor so it doesn't make sense to make it into its own
 * header/cpp.
 */
class TranslateDebugVisitor : public ConstElementVisitor
{
public:

  TranslateDebugVisitor(ScriptTranslatorPtr translatorIn, ScriptToOgrTranslatorPtr translatorOut,
    OsmMapPtr destination) :
    _destination(destination),
    _translatorIn(translatorIn),
    _translatorOut(translatorOut)
  {

    _deriveTags.reset(Factory::getInstance().constructObject<ElementVisitor>(
      std::string("hoot::DeriveImplicitTagsVisitor")));
  }

  virtual void visit(const ConstElementPtr& e)
  {
    geos::geom::GeometryTypeId gt = ElementConverter::getGeometryType(e, false);

    Tags origTags = e->getTags();
    Tags inTags = e->getTags();

    ConstNodePtr n;
    if (e->getElementType() == ElementType::Node)
    {
      n = boost::dynamic_pointer_cast<const Node>(e);
    }
    else
    {
      // if you want to add this you'll need to intelligently add the members of a relation/way
      // or update existing relation/ways. This gets kinda fugly with multiple features. Maybe
      // maintain all input elements, then just delete all the input elements that aren't being
      // used at the end. Dunno, but it isn't required at this time.
      LOG_WARN("Adding translate debug tags to non-nodes is not supported at this time.");
    }

    QString layer = inTags.get(MetadataTags::HootLayername());

    _translatorIn->translateToOsm(inTags, layer.toUtf8().data(), "Point");

    ElementPtr eCopy(e->clone());
    eCopy->setTags(inTags);
    _deriveTags->visit(eCopy);
    inTags = eCopy->getTags();

    std::vector<ScriptToOgrTranslator::TranslatedFeature> features =
      _translatorOut->translateToOgr(inTags, e->getElementType(), gt);

    const QString in = "in:";
    const QString out = "out:";

    Tags baseTags;

    foreach (const QString& key, origTags.keys())
    {
      baseTags[in + key] = origTags[key];
    }

    foreach (const ScriptToOgrTranslator::TranslatedFeature& f, features)
    {
      Tags tags = baseTags;
      tags[out + "hoot:tablename"] = f.tableName;

      const QVariantMap& vm = f.feature->getValues();
      for (QVariantMap::const_iterator it = vm.constBegin(); it != vm.constEnd(); ++it)
      {
        tags[out + it.key()] = it.value().toString();
      }

      if (n.get())
      {
        ElementPtr copy = Node::newSp(n->getStatus(), _destination->createNextNodeId(), n->getX(),
          n->getY(), n->getCircularError(), n->getChangeset(), n->getVersion(), n->getTimestamp(),
          n->getUser(), n->getUid(), n->getVisible());

        copy->setTags(tags);

        _destination->addElement(copy);
      }
    }
  }


private:
  OsmMapPtr _destination;
  ScriptTranslatorPtr _translatorIn;
  ScriptToOgrTranslatorPtr _translatorOut;
  ElementVisitorPtr _deriveTags;
};


TranslationDebugOp::TranslationDebugOp()
{

}

void TranslationDebugOp::apply(boost::shared_ptr<OsmMap>& map)
{
  // map a copy of the map, then clear the old map. This should be pretty quick/memory efficient.
  // technically, we could just change the map pointer, but some code may assume that isn't
  // happening so we'll code defensively.
  OsmMapPtr newCopy(new OsmMap(map));
  map->clear();

  ScriptTranslatorPtr translatorIn
    (ScriptTranslatorFactory::getInstance().createTranslator(_pathIn));
  if (translatorIn.get() == 0)
  {
    throw HootException("Translating to OGR requires a script that supports to OGR "
      "translations.");
  }

  ScriptTranslatorPtr t(ScriptTranslatorFactory::getInstance().createTranslator(_pathOut));
  ScriptToOgrTranslatorPtr translatorOut = boost::dynamic_pointer_cast<ScriptToOgrTranslator>(t);
  if (translatorOut.get() == 0)
  {
    throw HootException("Translating debug out requires a script that supports to OGR "
      "translations.");
  }

  // go through all the newCopy elements and copy them w/ translation into map.
  TranslateDebugVisitor v(translatorIn, translatorOut, map);
  newCopy->visitRo(v);
}

void TranslationDebugOp::setConfiguration(const Settings& conf)
{
  ConfigOptions c(conf);
  setScriptPath(c.getTranslationDebugInScript(), c.getTranslationDebugOutScript());
}

}
