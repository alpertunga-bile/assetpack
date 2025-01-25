cmake_minimum_required(VERSION 3.10.0)
project(pxd-assetpack VERSION 0.1.0 LANGUAGES C CXX)

LIST(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmakes)

set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/install)
set(BUILD_SHARED_LIBS OFF)

include(CTest)
enable_testing()

include(setup)

set_cxx(20)
enable_iwyu()

set(PXD_THIRD_PARTY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third-party)
set(PXD_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/includes)
set(PXD_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sources)

option(PXD_BUILD_TEST "Build test executable" OFF)

set(PXD_HEADER_FILES

    ${PXD_THIRD_PARTY_DIR}/meshoptimizer/src/meshoptimizer.h
    ${PXD_THIRD_PARTY_DIR}/FastLZ/fastlz.h
)

set(PXD_SOURCE_FILES
    ${PXD_THIRD_PARTY_DIR}/FastLZ/fastlz.c

    ${PXD_HEADER_FILES}
)

include_directories(
    ${PXD_INCLUDE_DIR}
    ${PXD_THIRD_PARTY_DIR}/assimp/include
    ${PXD_THIRD_PARTY_DIR}/rapidjson/include
)

set(COMMON_STD_HEADERS

)

# ------------------------------------------------------------------------------
# -- Third-party

# ---- Assimp
set(ASSIMP_NO_EXPORT ON)
set(ASSIMP_BUILD_TESTS OFF)
set(ASSIMP_INSTALL OFF)

add_subdirectory(${PXD_THIRD_PARTY_DIR}/assimp)

# ---- GLSLang
set(GLSLANG_TESTS_DEFAULT OFF)
set(GLSLANG_ENABLE_INSTALL_DEFAULT OFF)
set(ENABLE_GLSLANG_JS OFF)

add_subdirectory(${PXD_THIRD_PARTY_DIR}/glslang)

# ---- Mesh Optimizer
set(MESHOPT_INSTALL OFF)

add_subdirectory(${PXD_THIRD_PARTY_DIR}/meshoptimizer)

# ------------------------------------------------------------------------------

set(LIBS_TO_LINK
    assimp::assimp
    glslang
    meshoptimizer
)

add_executable(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp ${PXD_SOURCE_FILES})

target_link_libraries(${PROJECT_NAME} ${LIBS_TO_LINK})

target_precompile_headers(
    ${PROJECT_NAME} PRIVATE
    ${COMMON_STD_HEADERS}
    ${PXD_HEADER_FILES}
)

# ------------------------------------------------------------------------------
# -- Test Executable

if(PXD_BUILD_TEST)
    set(PXD_TEST_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

    set(PXD_TEST_PROJECT_NAME ${PROJECT_NAME}_test)

    set(PXD_TEST_SOURCE_FILES
        ${PXD_TEST_SOURCE_DIR}/test.cpp

        ${PXD_SOURCE_FILES}
    )

    include(FetchContent)
    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest/
        GIT_TAG main
    )

    if(WIN32)
        # For Windows: Prevent overriding the parent project's compiler/linker settings
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    endif(WIN32)
    FetchContent_MakeAvailable(googletest)

    enable_testing()

    add_executable(${PXD_TEST_PROJECT_NAME} ${PXD_TEST_SOURCE_FILES})

    target_link_libraries(${PXD_TEST_PROJECT_NAME} ${LIBS_TO_LINK} GTest::gtest_main)

    include(GoogleTest)
    gtest_discover_tests(${PXD_TEST_PROJECT_NAME})

    target_precompile_headers(
        ${PXD_TEST_PROJECT_NAME} PRIVATE
        ${COMMON_STD_HEADERS}
        ${PXD_HEADER_FILES}
    )

endif()
unset(PXD_BUILD_TEST CACHE)

set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
include(CPack)
        
