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
 * @copyright Copyright (C) 2015, 2017, 2018, 2019 DigitalGlobe (http://www.digitalglobe.com/)
 */

#include "StringUtils.h"

// Hoot
#include <hoot/core/util/HootException.h>
#include <hoot/core/util/Log.h>

// Qt
#include <QLocale>

namespace hoot
{

QString StringUtils::secondsToDhms(const qint64 durationInMilliseconds)
{
  QString res;
  int duration = (int)(durationInMilliseconds / 1000);
  const int seconds = (int)(duration % 60);
  duration /= 60;
  const int minutes = (int)(duration % 60);
  duration /= 60;
  const int hours = (int)(duration % 24);
  const int days = (int)(duration / 24);
  if ((hours == 0) && (days == 0))
  {
    return res.sprintf("%02d:%02d", minutes, seconds);
  }
  if (days == 0)
  {
    return res.sprintf("%02d:%02d:%02d", hours, minutes, seconds);
  }
  return res.sprintf("%dd%02d:%02d:%02d", days, hours, minutes, seconds);
}

QString StringUtils::formatLargeNumber(const unsigned long number)
{
  //I want to see comma separators...probably a better way to handle this...will go with this for
  //now.
  const QLocale& cLocale = QLocale::c();
  QString ss = cLocale.toString((qulonglong)number);
  ss.replace(cLocale.groupSeparator(), ',');
  return ss;
}

bool StringUtils::hasAlphabeticCharacter(const QString input)
{
  for (int i = 0; i < input.length(); i++)
  {
    if (input.at(i).isLetter())
    {
      return true;
    }
  }
  return false;
}

bool StringUtils::hasDigit(const QString input)
{
  for (int i = 0; i < input.length(); i++)
  {
    if (input.at(i).isDigit())
    {
      return true;
    }
  }
  return false;
}

bool StringUtils::isNumber(const QString input)
{
  bool isNumber = false;
  input.toLong(&isNumber);
  return isNumber;
}

boost::shared_ptr<boost::property_tree::ptree> StringUtils::jsonStringToPropTree(QString jsonStr)
{
  LOG_VART(jsonStr);
  std::stringstream strStrm(jsonStr.toUtf8().constData(), std::ios::in);
  if (!strStrm.good())
  {
    throw HootException(QString("Error reading from reply string:\n%1").arg(jsonStr));
  }
  boost::shared_ptr<boost::property_tree::ptree> jsonObj(new boost::property_tree::ptree());
  try
  {
    boost::property_tree::read_json(strStrm, *jsonObj);
  }
  catch (boost::property_tree::json_parser::json_parser_error& e)
  {
    QString reason = QString::fromStdString(e.message());
    QString line = QString::number(e.line());
    throw HootException(QString("Error parsing JSON: %1 (line %2)").arg(reason).arg(line));
  }
  return jsonObj;
}

boost::shared_ptr<boost::property_tree::ptree> StringUtils::stringListToJsonStringArray(
  const QStringList stringList)
{
  boost::shared_ptr<boost::property_tree::ptree> strArr(new boost::property_tree::ptree());
  for (int i = 0; i < stringList.size(); i++)
  {
    boost::property_tree::ptree str;
    str.put("", stringList.at(i).toStdString());
    strArr->push_back(std::make_pair("", str));
  }
  return strArr;
}

QString StringUtils::getNumberStringPaddedWithZeroes(const int number, const int padSize)
{
  return QString("%1").arg(number, padSize, 10, QChar('0'));
}

}
