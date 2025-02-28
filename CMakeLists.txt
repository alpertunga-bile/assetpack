cmake_minimum_required(VERSION 3.10.0)
project(pxd-assetpack VERSION 0.1.0 LANGUAGES C CXX)

LIST(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmakes)

set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/install)
set(BUILD_SHARED_LIBS OFF)

include(CTest)
enable_testing()

set(CXX_VERSION 20)
set(CMAKE_CXX_STANDARD ${CXX_VERSION})
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++${CXX_VERSION}")
endif()

if(NOT WIN32)
  set(IWYU_ARGS "include-what-you-use -w -Xiwyu --verbose=7")
  add_compile_definitions(CMAKE_CXX_INCLUDE_WHAT_YOU_USE=${IWYU_ARGS})
endif(NOT WIN32)

if(${CMAKE_BUILD_TYPE} MATCHES "Release")

  message(STATUS "Optimizations are opened for ${PROJECT_NAME}")

  include(CheckIPOSupported)
  check_ipo_supported(RESULT is_supported OUTPUT error)

  if(is_supported)
    message(STATUS "Opening LTO")
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
  endif(is_supported)

  if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(STATUS "Adding -O3 -march=native flags")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -march=native")
  endif(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")

endif(${CMAKE_BUILD_TYPE} MATCHES "Release")

set(PXD_THIRD_PARTY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third-party)
set(PXD_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/includes)
set(PXD_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sources)

option(PXD_BUILD_TEST "Build test executable" OFF)

set(PXD_HEADER_FILES

    ${PXD_THIRD_PARTY_DIR}/FastLZ/fastlz.h
)

set(PXD_SOURCE_FILES
    ${PXD_THIRD_PARTY_DIR}/FastLZ/fastlz.c

    ${PXD_HEADER_FILES}
)

include_directories(
    ${PXD_INCLUDE_DIR}
)

set(COMMON_STD_HEADERS

)

# ------------------------------------------------------------------------------
# -- Third-party

include(FetchContent)

# ---- Rapidjson
set(RAPIDJSON_BUILD_DOC OFF)
set(RAPIDJSON_BUILD_EXAMPLES OFF)
set(RAPIDJSON_BUILD_TESTS OFF)

FetchContent_Declare(
  rapidjson
  GIT_REPOSITORY https://github.com/Tencent/rapidjson.git
  GIT_TAG master
  GIT_SHALLOW 1
)

# ---- Assimp
set(ASSIMP_NO_EXPORT ON)
set(ASSIMP_BUILD_TESTS OFF)
set(ASSIMP_INSTALL OFF)

FetchContent_Declare(
  assimp
  GIT_REPOSITORY https://github.com/assimp/assimp.git
  GIT_TAG master
  GIT_SHALLOW 1
)

# ---- GLSLang
set(GLSLANG_TESTS_DEFAULT OFF)
set(GLSLANG_ENABLE_INSTALL_DEFAULT OFF)
set(ENABLE_GLSLANG_JS OFF)

add_subdirectory(${PXD_THIRD_PARTY_DIR}/glslang)

# ---- Mesh Optimizer
set(MESHOPT_INSTALL OFF)

FetchContent_Declare(
  meshoptimizer
  GIT_REPOSITORY https://github.com/zeux/meshoptimizer.git
  GIT_TAG master
  GIT_SHALLOW 1
)

# ---- Cryptopp
FetchContent_Declare(
  cryptopp_lib
  GIT_REPOSITORY https://github.com/abdes/cryptopp-cmake.git
  GIT_TAG f815f6284684be6ab03af4b6c273359331c61241
  GIT_SHALLOW 1
)

FetchContent_MakeAvailable(
  cryptopp_lib
  meshoptimizer
  assimp
  rapidjson
)

# ------------------------------------------------------------------------------

set(LIBS_TO_LINK
    assimp::assimp
    glslang
    meshoptimizer
    cryptopp::cryptopp
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
