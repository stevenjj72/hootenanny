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
#include "SparkWriter.h"

// geos
#include <geos/geom/Envelope.h>

using namespace geos::geom;

// hoot
#include <hoot/core/conflate/MatchFactory.h>
//#include <hoot/core/io/OsmJsonWriter.h>
#include <hoot/core/util/ConfigOptions.h>
#include <hoot/core/util/Exception.h>
#include <hoot/core/util/Factory.h>
#include <hoot/core/util/Log.h>
#include <hoot/core/visitors/CalculateHashVisitor.h>
#include <hoot/rnd/conflate/multiary/MultiaryUtilities.h>
#include <hoot/core/util/StringUtils.h>

// Qt
#include <QStringBuilder>
#include <QFileInfo>

namespace hoot
{

HOOT_FACTORY_REGISTER(OsmMapWriter, SparkWriter)

using namespace boost;

SparkWriter::SparkWriter() :
_precision(round(ConfigOptions().getWriterPrecision())),
_nodeCtr(0),
_logUpdateInterval(ConfigOptions().getApidbBulkInserterFileOutputStatusUpdateInterval())
{
}

void SparkWriter::open(QString fileName)
{
  close();

  QFileInfo fileInfo(fileName);

  _fp.reset(new QFile());
  const QString addFileName =
    fileInfo.absolutePath() + "/" + fileInfo.baseName() + "-add." + fileInfo.completeSuffix();
  _fp->setFileName(addFileName);
  if (_fp->exists() && !_fp->remove())
  {
    throw HootException(QObject::tr("Error removing existing %1 for writing.").arg(addFileName));
  }
  if (!_fp->open(QIODevice::WriteOnly | QIODevice::Text))
  {
    throw HootException(QObject::tr("Error opening %1 for writing").arg(addFileName));
  }

  // find a match creator that can provide the search bounds.
  foreach (boost::shared_ptr<MatchCreator> mc, MatchFactory::getInstance().getCreators())
  {
    SearchRadiusProviderPtr sbc = dynamic_pointer_cast<SearchRadiusProvider>(mc);

    if (sbc.get())
    {
      if (_bounds.get())
      {
        LOG_WARN("Found more than one bounds calculator. Using the first one.");
      }
      else
      {
        _bounds.reset(new SearchBoundsCalculator(sbc));
      }
    }
  }

  if (!_bounds.get())
  {
    throw HootException("You must specify one match creator that supports search radius "
      "calculation.");
  }
}

void SparkWriter::writePartial(const ConstNodePtr& n)
{
  NodePtr copy(dynamic_cast<Node*>(n->clone()));
  _addExportTagsVisitor.visit(copy);
  Envelope e = _bounds->calculateSearchBounds(OsmMapPtr(), copy);

  QString result;
  // 600 was picked b/c OSM POI records were generally ~500.
  result.reserve(600);

  result += QString::number(e.getMinX(), 'g', 16) % "\t";
  result += QString::number(e.getMinY(), 'g', 16) % "\t";
  result += QString::number(e.getMaxX(), 'g', 16) % "\t";
  result += QString::number(e.getMaxY(), 'g', 16) % "\t";
  /// @todo Update after https://github.com/ngageoint/hootenanny/issues/1663
  result += CalculateHashVisitor::toHashString(n) % "\t";
  result += QString(MultiaryUtilities::convertElementToPbf(copy).toBase64().data()) + "\n";

  if (_fp->write(result.toUtf8()) == -1)
  {
    throw HootException("Error writing to file: " + _fp->errorString());
  }

  _nodeCtr++;
  if (_nodeCtr % _logUpdateInterval == 0)
  {
    PROGRESS_INFO(StringUtils::formatLargeNumber(_nodeCtr) << " nodes written.");
  }
}

}
