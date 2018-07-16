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
 * @copyright Copyright (C) 2018 DigitalGlobe (http://www.digitalglobe.com/)
 */

#ifndef OSM_API_NETWORK_REQUEST_H
#define OSM_API_NETWORK_REQUEST_H

//  Boost
#include <boost/shared_ptr.hpp>

//  Qt
#include <QList>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>
#include <QUrl>

namespace hoot
{

/** Class for sending HTTP network requests to an OSM API */
class OsmApiNetworkRequest
{
public:
  /** Constructor */
  OsmApiNetworkRequest();
  /**
   * @brief networkRequest Function to make the actual request
   * @param url URL for the request
   * @param http_op HTTP operation (GET, POST, or PUT), GET is default
   * @param data POST data as a QByteArray
   * @return success
   */
  bool networkRequest(QUrl url,
    QNetworkAccessManager::Operation http_op = QNetworkAccessManager::Operation::GetOperation,
    const QByteArray& data = QByteArray());
  /**
   * @brief getResponseContent
   * @return HTTP response content
   */
  const QByteArray& getResponseContent() { return _content; }
  /**
   * @brief getHttpStatus
   * @return HTTP status code
   */
  int getHttpStatus() { return _status; }

private:
  /**
   * @brief _getHttpResponseCode Get the HTTP response code from the response object
   * @param reply Network reply object
   * @return HTTP response code as a number, 200 instead of "200"
   */
  int _getHttpResponseCode(QNetworkReply* reply);
  /** HTTP response body, if available */
  QByteArray _content;
  /** HTTP status response code  */
  int _status;
};

typedef boost::shared_ptr<OsmApiNetworkRequest> OsmApiNetworkRequestPtr;

}

#endif  //  OSM_API_NETWORK_REQUEST_H
