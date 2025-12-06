// DocumentModel.cpp
// Implementation of the plain text document model.

#include "DocumentModel.h"

#include <fstream>
#include <sstream>

DocumentModel::DocumentModel() : text_(), filePath_(), dirty_(false) {}

void DocumentModel::setText(const std::string &text) {
    text_ = text;
    dirty_ = true;
}

const std::string &DocumentModel::text() const { return text_; }

void DocumentModel::setFilePath(const std::string &path) { filePath_ = path; }

const std::string &DocumentModel::filePath() const { return filePath_; }

bool DocumentModel::hasFilePath() const { return !filePath_.empty(); }

bool DocumentModel::isDirty() const { return dirty_; }

void DocumentModel::markClean() { dirty_ = false; }

bool DocumentModel::loadFromFile(const std::string &path, std::string &outError) {
    std::ifstream file(path, std::ios::in | std::ios::binary);
    if (!file) {
        outError = "Failed to open file for reading.";
        return false;
    }

    std::ostringstream buffer;
    buffer << file.rdbuf();
    if (file.bad()) {
        outError = "Failed while reading file.";
        return false;
    }

    text_ = buffer.str();
    filePath_ = path;
    dirty_ = false;
    return true;
}

bool DocumentModel::save(std::string &outError) {
    if (filePath_.empty()) {
        outError = "No file path set.";
        return false;
    }
    return saveAs(filePath_, outError);
}

bool DocumentModel::saveAs(const std::string &path, std::string &outError) {
    std::ofstream file(path, std::ios::out | std::ios::binary | std::ios::trunc);
    if (!file) {
        outError = "Failed to open file for writing.";
        return false;
    }

    file.write(text_.data(), static_cast<std::streamsize>(text_.size()));
    if (!file) {
        outError = "Failed while writing file.";
        return false;
    }

    filePath_ = path;
    dirty_ = false;
    return true;
}
