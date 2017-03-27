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
 * @copyright Copyright (C) 2016, 2017 DigitalGlobe (http://www.digitalglobe.com/)
 */
package hoot.services.utils;

import static hoot.services.HootProperties.UPLOAD_FOLDER;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.FilenameUtils;
import org.glassfish.jersey.media.multipart.BodyPart;
import org.glassfish.jersey.media.multipart.FormDataMultiPart;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public final class MultipartSerializer {
    private static final Logger logger = LoggerFactory.getLogger(MultipartSerializer.class);

    private MultipartSerializer() {}

    /**
     * Serializes uploaded multipart data into files. It can handle file or folder type.
     *
     * @param inputType
     *            = ["FILE" | "DIR"] where DIR type is treated as FGDB
     * @param multiPart
     *            = The request object that holds post data
     * @param destinationDir
     *            = Directory where to store uploaded files
     */
    public static Map<File, String> serializeUpload(String inputType, FormDataMultiPart multiPart, File destinationDir) {
        if (!Arrays.asList("FILE", "DIR").contains(inputType.toUpperCase())) {
            throw new IllegalArgumentException("Unsupported inputType: " + inputType);
        }

        Map<File, String> uploadedFiles = new HashMap<>();

        List<String> supportedExtensions = Arrays.asList("OSM", "GEONAMES", "SHP", "ZIP", "PBF", "TXT");
        List<BodyPart> bodyParts = multiPart.getBodyParts();

        for (BodyPart fileItem : bodyParts) {
            String fileName = fileItem.getContentDisposition().getFileName();

            if (fileName == null) {
                throw new RuntimeException("A valid file name was not specified.");
            }

            File uploadedFile = new File(destinationDir, fileName);

            validatePath(new File(UPLOAD_FOLDER), uploadedFile);

            try (InputStream fileStream = fileItem.getEntityAs(InputStream.class)) {
                FileUtils.copyInputStreamToFile(fileStream, uploadedFile);
            }
            catch (Exception ioe) {
                throw new RuntimeException("Error saving file to disk: " + uploadedFile, ioe);
            }

            String extension = FilenameUtils.getExtension(fileName).toUpperCase();

            if (inputType.equalsIgnoreCase("FILE")) {
                if (supportedExtensions.contains(extension)) {
                    uploadedFiles.put(uploadedFile, extension);
                    logger.debug("Successfully uploaded file: {}", uploadedFile.getAbsolutePath());
                }
                else {
                    logger.info("Skipping upload of {} file.  Extension {} not supported!", fileName, extension);
                }
            }
            else if (inputType.equalsIgnoreCase("DIR")) {
                //If user request type is DIR then treat it as FGDB folder
                extension = "GDB";
                uploadedFiles.put(uploadedFile, extension);
            }
        }

        return uploadedFiles;
    }

    // See #6760
    // Stop file path manipulation vulnerability by validating the new path is
    // within container path
    private static void validatePath(File basePath, File newPath) {
        boolean isValidPath = false;

        try {
            String potentialPath = newPath.getCanonicalPath();
            String containerPath = basePath.getCanonicalPath();

            // verify that newPath is within basePath
            isValidPath = potentialPath.indexOf(containerPath) == 0;
        }
        catch (IOException ex) {
            logger.error("Failed to validate MultipartSerializer path: {}", ex.getMessage());
        }

        if (!isValidPath) {
            throw new RuntimeException("Illegal path: " + newPath.getAbsolutePath());
        }
    }
}
