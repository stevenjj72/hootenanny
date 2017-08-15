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
#include "MultiaryUtilities.h"

// hoot
#include <hoot/core/conflate/MatchFactory.h>
#include <hoot/core/conflate/MergerFactory.h>
#include <hoot/core/conflate/UnifyingConflator.h>
#include <hoot/rnd/conflate/multiary/MultiaryPoiMergerCreator.h>

namespace hoot
{

void MultiaryUtilities::conflate(OsmMapPtr map)
{
  MatchFactory& matchFactory = MatchFactory::getInstance();
  matchFactory.reset();
  matchFactory.registerCreator("hoot::ScriptMatchCreator,MultiaryPoiGeneric.js");

  MergerFactory::getInstance().reset();
  boost::shared_ptr<MergerFactory> mergerFactory(new MergerFactory());
  mergerFactory->registerCreator(new MultiaryPoiMergerCreator());

  MatchThresholdPtr mt(new MatchThreshold(0.39, 0.61, 1.1));

  // call new conflation routine
  UnifyingConflator conflator(mt);
  conflator.setMergerFactory(mergerFactory);
  conflator.apply(map);
}

}