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

#ifndef TOOGRTRANSLATIONDEBUGOP_H
#define TOOGRTRANSLATIONDEBUGOP_H

// hoot
#include <hoot/core/util/Configurable.h>

#include "OsmMapOperation.h"

namespace hoot
{

class TranslationDebugOp : public OsmMapOperation, public Configurable
{
public:
  static std::string className() { return "hoot::TranslationDebugOp"; }

  TranslationDebugOp();

  /**
   * Traverse the supplied OSM Map and translate all features currently in the map to a debug
   * marked up equivalent.
   *
   * This honors the one to many feature translation and
   */
  virtual void apply(boost::shared_ptr<OsmMap>& map);

  virtual void setConfiguration(const Settings& conf);

  void setScriptPath(QString pathIn, QString pathOut) { _pathIn = pathIn; _pathOut = pathOut; }

private:
  QString _pathIn, _pathOut;
};

}

#endif // TOOGRTRANSLATIONDEBUGOP_H
