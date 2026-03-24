import 'package:file_convertor/features/file_conversion/data/models/conversion_section.dart';
import 'package:flutter/material.dart';

final List<ConversionSection> conversionSections = [
  /// ------------------------------------------------------------
  /// PDF TO ALL
  /// ------------------------------------------------------------
  ConversionSection(
    title: "PDF TO ALL",
    items: [
      ConversionItem(
        title: "PDF to DOCX",
        icon: Icons.description,
        color: Colors.blue,
      ),
      ConversionItem(
        title: "PDF to DOC",
        icon: Icons.description,
        color: Colors.blue,
      ),
      ConversionItem(
        title: "PDF to ODT",
        icon: Icons.history_edu,
        color: Colors.blue,
      ),
      ConversionItem(
        title: "PDF to RTF",
        icon: Icons.article,
        color: Colors.blue,
      ),
      ConversionItem(
        title: "PDF to TXT",
        icon: Icons.text_snippet,
        color: Colors.blue,
      ),
      ConversionItem(
        title: "PDF to HTML",
        icon: Icons.code,
        color: Colors.blue,
      ),
      ConversionItem(
        title: "PDF to JPG",
        icon: Icons.image,
        color: Colors.blue,
      ),
      ConversionItem(
        title: "PDF to PNG",
        icon: Icons.image_outlined,
        color: Colors.blue,
      ),
      ConversionItem(
        title: "PDF to Images",
        icon: Icons.collections,
        color: Colors.blue,
      ),
    ],
  ),

  /// ------------------------------------------------------------
  /// WORD TO ALL
  /// ------------------------------------------------------------
  ConversionSection(
    title: "WORD TO ALL",
    items: [
      ConversionItem(
        title: "DOC to DOCX",
        icon: Icons.description,
        color: Colors.indigo,
      ),
      ConversionItem(
        title: "DOCX to DOC",
        icon: Icons.description,
        color: Colors.indigo,
      ),
      ConversionItem(
        title: "DOCX to PDF",
        icon: Icons.picture_as_pdf,
        color: Colors.indigo,
      ),
      ConversionItem(
        title: "DOCX to ODT",
        icon: Icons.history_edu,
        color: Colors.indigo,
      ),
      ConversionItem(
        title: "DOCX to RTF",
        icon: Icons.article,
        color: Colors.indigo,
      ),
      ConversionItem(
        title: "DOCX to TXT",
        icon: Icons.text_snippet,
        color: Colors.indigo,
      ),
      ConversionItem(
        title: "DOCX to HTML",
        icon: Icons.code,
        color: Colors.indigo,
      ),
    ],
  ),

  /// ------------------------------------------------------------
  /// TEXT & DATA TO ALL
  /// ------------------------------------------------------------
  ConversionSection(
    title: "TEXT & DATA TO ALL",
    items: [
      ConversionItem(
        title: "TXT to PDF",
        icon: Icons.picture_as_pdf,
        color: Colors.blueGrey,
      ),
      ConversionItem(
        title: "TXT to DOCX",
        icon: Icons.description,
        color: Colors.blueGrey,
      ),
      ConversionItem(
        title: "CSV to XLSX",
        icon: Icons.table_chart,
        color: Colors.blueGrey,
      ),
      ConversionItem(
        title: "CSV to JSON",
        icon: Icons.data_array,
        color: Colors.blueGrey,
      ),
      ConversionItem(
        title: "JSON to CSV",
        icon: Icons.data_array,
        color: Colors.blueGrey,
      ),
      ConversionItem(
        title: "XML to JSON",
        icon: Icons.code,
        color: Colors.blueGrey,
      ),
      ConversionItem(
        title: "JSON to XML",
        icon: Icons.code,
        color: Colors.blueGrey,
      ),
      ConversionItem(
        title: "Markdown to PDF",
        icon: Icons.article,
        color: Colors.blueGrey,
      ),
      ConversionItem(
        title: "Markdown to HTML",
        icon: Icons.code,
        color: Colors.blueGrey,
      ),
    ],
  ),

  /// ------------------------------------------------------------
  /// PNG TO ALL
  /// ------------------------------------------------------------
  ConversionSection(
    title: "PNG TO ALL",
    items: [
      ConversionItem(
        title: "PNG to JPG",
        icon: Icons.image,
        color: Colors.orange,
      ),
      ConversionItem(
        title: "PNG to JPEG",
        icon: Icons.image,
        color: Colors.orange,
      ),
      ConversionItem(
        title: "PNG to WebP",
        icon: Icons.animation,
        color: Colors.orange,
      ),
      ConversionItem(
        title: "PNG to BMP",
        icon: Icons.image,
        color: Colors.orange,
      ),
      ConversionItem(
        title: "PNG to TIFF",
        icon: Icons.collections,
        color: Colors.orange,
      ),
      ConversionItem(
        title: "PNG to GIF",
        icon: Icons.gif,
        color: Colors.orange,
      ),
      ConversionItem(
        title: "PNG to PDF",
        icon: Icons.picture_as_pdf,
        color: Colors.orange,
      ),
    ],
  ),

  /// ------------------------------------------------------------
  /// JPG / JPEG TO ALL
  /// ------------------------------------------------------------
  ConversionSection(
    title: "JPG / JPEG TO ALL",
    items: [
      ConversionItem(
        title: "JPG to PNG",
        icon: Icons.image,
        color: Colors.deepOrange,
      ),
      ConversionItem(
        title: "JPG to WebP",
        icon: Icons.animation,
        color: Colors.deepOrange,
      ),
      ConversionItem(
        title: "JPG to BMP",
        icon: Icons.image,
        color: Colors.deepOrange,
      ),
      ConversionItem(
        title: "JPG to TIFF",
        icon: Icons.collections,
        color: Colors.deepOrange,
      ),
      ConversionItem(
        title: "JPG to GIF",
        icon: Icons.gif,
        color: Colors.deepOrange,
      ),
      ConversionItem(
        title: "JPG to PDF",
        icon: Icons.picture_as_pdf,
        color: Colors.deepOrange,
      ),
    ],
  ),

  /// ------------------------------------------------------------
  /// IMAGE UTILITIES
  /// ------------------------------------------------------------
  ConversionSection(
    title: "IMAGE UTILITIES",
    items: [
      ConversionItem(
        title: "HEIC to JPG",
        icon: Icons.image,
        color: Colors.orangeAccent,
      ),
      ConversionItem(
        title: "Images to PDF",
        icon: Icons.picture_as_pdf,
        color: Colors.orangeAccent,
      ),
      ConversionItem(
        title: "Compress Images",
        icon: Icons.compress,
        color: Colors.orangeAccent,
      ),
    ],
  ),

  /// ------------------------------------------------------------
  /// MP4 TO ALL
  /// ------------------------------------------------------------
  ConversionSection(
    title: "MP4 TO ALL",
    items: [
      ConversionItem(
        title: "MP4 to AVI",
        icon: Icons.movie,
        color: Colors.green,
      ),
      ConversionItem(
        title: "MP4 to MOV",
        icon: Icons.movie_filter,
        color: Colors.green,
      ),
      ConversionItem(
        title: "MP4 to MKV",
        icon: Icons.movie,
        color: Colors.green,
      ),
      ConversionItem(
        title: "MP4 to WebM",
        icon: Icons.movie,
        color: Colors.green,
      ),
      ConversionItem(title: "MP4 to GIF", icon: Icons.gif, color: Colors.green),
      ConversionItem(
        title: "MP4 to MP3",
        icon: Icons.audiotrack,
        color: Colors.green,
      ),
      ConversionItem(
        title: "MP4 to WAV",
        icon: Icons.audiotrack,
        color: Colors.green,
      ),
    ],
  ),

  /// ------------------------------------------------------------
  /// AUDIO TO ALL
  /// ------------------------------------------------------------
  ConversionSection(
    title: "AUDIO TO ALL",
    items: [
      ConversionItem(
        title: "MP3 to WAV",
        icon: Icons.audiotrack,
        color: Colors.teal,
      ),
      ConversionItem(
        title: "MP3 to AAC",
        icon: Icons.audiotrack,
        color: Colors.teal,
      ),
      ConversionItem(
        title: "MP3 to OGG",
        icon: Icons.audiotrack,
        color: Colors.teal,
      ),
      ConversionItem(
        title: "MP3 to FLAC",
        icon: Icons.high_quality,
        color: Colors.teal,
      ),
      ConversionItem(
        title: "WAV to MP3",
        icon: Icons.audiotrack,
        color: Colors.teal,
      ),
      ConversionItem(
        title: "M4A to MP3",
        icon: Icons.audiotrack,
        color: Colors.teal,
      ),
      ConversionItem(
        title: "Audio to Text (Speech)",
        icon: Icons.record_voice_over,
        color: Colors.teal,
      ),
    ],
  ),

  /// ------------------------------------------------------------
  /// ARCHIVE & COMPRESSION
  /// ------------------------------------------------------------
  ConversionSection(
    title: "ARCHIVE & COMPRESSION",
    items: [
      ConversionItem(
        title: "ZIP to RAR",
        icon: Icons.unarchive,
        color: Colors.purple,
      ),
      ConversionItem(
        title: "RAR to ZIP",
        icon: Icons.unarchive,
        color: Colors.purple,
      ),
      ConversionItem(
        title: "7Z to ZIP",
        icon: Icons.inventory_2,
        color: Colors.purple,
      ),
      ConversionItem(
        title: "TAR to ZIP",
        icon: Icons.inventory_2,
        color: Colors.purple,
      ),
      ConversionItem(
        title: "Extract Archive",
        icon: Icons.folder_open,
        color: Colors.purple,
      ),
      ConversionItem(
        title: "Compress Files",
        icon: Icons.compress,
        color: Colors.purple,
      ),
    ],
  ),
];
