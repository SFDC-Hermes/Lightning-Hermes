public with sharing class FileService {
    private static final Integer DEFAULT_PAGE_SIZE = 40;
    private static final Integer MAX_PAGE_SIZE = 200;
    private static final Integer EXTRA_ROW_FOR_HAS_MORE = 1;
    private static final Set<String> IMAGE_EXTENSIONS = new Set<String>{ 'png', 'jpg', 'jpeg', 'gif', 'bmp', 'svg', 'webp' };
    private static final Map<String, String> ICON_MAP = new Map<String, String>{
        'pdf' => 'doctype:pdf',
        'png' => 'doctype:image',
        'jpg' => 'doctype:image',
        'jpeg' => 'doctype:image',
        'gif' => 'doctype:image',
        'bmp' => 'doctype:image',
        'svg' => 'doctype:image',
        'webp' => 'doctype:image',
        'doc' => 'doctype:word',
        'docx' => 'doctype:word',
        'xls' => 'doctype:excel',
        'xlsx' => 'doctype:excel',
        'ppt' => 'doctype:ppt',
        'pptx' => 'doctype:ppt',
        'csv' => 'doctype:csv',
        'json' => 'doctype:code',
        'txt' => 'doctype:txt',
        'zip' => 'doctype:zip'
    };
}
