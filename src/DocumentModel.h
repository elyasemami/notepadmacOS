// DocumentModel.h
// Plain text document state for the Notepad clone.
//
// This is the Model part of MVC: it owns the current text buffer,
// file path metadata, and dirty tracking, while remaining UI-agnostic.

#pragma once

#include <string>

class DocumentModel {
public:
    DocumentModel();

    // Replace the in-memory text and mark the document dirty.
    void setText(const std::string &text);
    const std::string &text() const;

    // File path helpers.
    void setFilePath(const std::string &path);
    const std::string &filePath() const;
    bool hasFilePath() const;

    // Dirty flag helpers.
    bool isDirty() const;
    void markClean();

    // Load/save text content. Returns true on success, false on error
    // with the error string populated.
    bool loadFromFile(const std::string &path, std::string &outError);
    bool save(std::string &outError);                  // Saves to filePath_.
    bool saveAs(const std::string &path, std::string &outError); // Saves to given path and updates filePath_.

private:
    std::string text_;
    std::string filePath_;
    bool dirty_;
};
