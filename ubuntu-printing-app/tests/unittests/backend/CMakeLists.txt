include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/ubuntu-printing-app/backend/
)

find_package(Qt5Test REQUIRED)

add_executable(testDocument tst_document.cpp ${PDF_TEST_FILES})
target_link_libraries(testDocument UbuntuPrintingAppbackend Qt5::Test Qt5::Gui)
add_test(tst_document testDocument)

add_executable(testPageHelper tst_pagehelper.cpp ${PDF_TEST_FILES})
target_link_libraries(testPageHelper UbuntuPrintingAppbackend Qt5::Test Qt5::Gui)
add_test(tst_pagehelper testPageHelper)

add_executable(testPopplerImageProvider tst_popplerimageprovider.cpp ${PDF_TEST_FILES})
target_link_libraries(testPopplerImageProvider UbuntuPrintingAppbackend Qt5::Test Qt5::Gui)
add_test(tst_popplerimageprovider testPopplerImageProvider)
