#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: GPLv2 or later
# Created: 2017-06-16
# Updated: 2020-05-10
# Version: N/A

set -e

export CUR_DIR="$(dirname $(realpath -s ${0}))"
export MAIN_DIR="$(realpath -s ${CUR_DIR}/..)"

PSI_DIR="${MAIN_DIR}/psi"
PLUGINS_DIR="${MAIN_DIR}/plugins"
PSIMEDIA_DIR="${MAIN_DIR}/psimedia"
PSIPLUS_L10N_DIR="${MAIN_DIR}/psi-plus-l10n"

# master release-1.x
PSI_RELEASE_BRANCH="master"

cd "${CUR_DIR}"

case "${1}" in
"up")
    # Pulling changes from GitHub repo.

    git pull --all

;;
"cm")
    # Creating correct git commit.

    git commit -a -m 'Sync translations with Psi+ project.'

;;
"push")
    # Pushing changes into GitHub repo.

    git push
    git push --tags

;;
"make")
    # Making precompiled localization files.

    rm translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo translations/*.ts >> translations.pro

    lrelease ./translations.pro

    mkdir -p out
    mv translations/*.qm out/

;;
"install")
    # Installing precompiled localization files into default directory.

    if [ ${USER} != "root" ]; then
        echo "You are not a root now!"
        exit 1
    fi

    mkdir -p /usr/share/psi/translations/
    cp out/*.qm /usr/share/psi/translations/

;;
"tarball")
    # Generating tarball with precompiled localization files.

    CUR_TAG="$(git tag -l  | sort -r -V | head -n1)"

    rm -rf psi-translations-*
    mkdir psi-translations-${CUR_TAG}
    cp out/*.qm psi-translations-${CUR_TAG}

    tar -cJf psi-translations-${CUR_TAG}.tar.xz psi-translations-${CUR_TAG}
    echo "Tarball with precompiled translation files is ready for upload:"
    [ ! -z "$(which realpath)" ] && echo "$(realpath ${CUR_DIR}/psi-translations-${CUR_TAG}.tar.xz)"
    echo "https://sourceforge.net/projects/psi/files/Translations/"

;;
"tr")
    # Pulling updates from Psi+ project.

    # Test Internet connection:
    host github.com > /dev/null

    git status

    if [ -d "${PSIPLUS_L10N_DIR}" ]; then
        echo "Updating ${PSIPLUS_L10N_DIR}"
        cd "${PSIPLUS_L10N_DIR}"
        git pull --all --prune
        echo;
    else
        echo "Creating ${PSIPLUS_L10N_DIR}"
        cd "${MAIN_DIR}"
        git clone https://github.com/psi-plus/psi-plus-l10n.git
        echo;
    fi

    cp -a "${PSIPLUS_L10N_DIR}/translations"/*.ts "${CUR_DIR}/translations/"
    cp -a "${PSIPLUS_L10N_DIR}/desktop-file"/*.desktop "${CUR_DIR}/desktop-file/"

    cp -a "${PSIPLUS_L10N_DIR}/AUTHORS" "${CUR_DIR}/"
    cp -a "${PSIPLUS_L10N_DIR}/COPYING" "${CUR_DIR}/"

    # find "${CUR_DIR}/translations/" -type f -exec sed -i "s|Psi+|Psi|g" {} \;
    find "${CUR_DIR}/desktop-file/" -type f -exec sed -i "s|Psi+|Psi|g" {} \;
    find "${CUR_DIR}/desktop-file/" -type f -exec sed -i "s|Psi-plus|Psi|g" {} \;
    find "${CUR_DIR}/desktop-file/" -type f -exec sed -i "s|psi-plus|psi|g" {} \;

    cd "${CUR_DIR}"
    git status

;;
"tr_up")
    # Full update of localization files.

    git status

    if [ -d "${PSI_DIR}" ]; then
        echo "Updating ${PSI_DIR}"
        cd "${PSI_DIR}"
        git checkout .
        git checkout "${PSI_RELEASE_BRANCH}"
        git pull --all --prune
        git submodule init
        git submodule update
        echo;
    else
        echo "Creating ${PSI_DIR}"
        cd "${MAIN_DIR}"
        git clone https://github.com/psi-im/psi.git
        cd "${PSI_DIR}"
        git checkout "${PSI_RELEASE_BRANCH}"
        git submodule init
        git submodule update
        echo;
    fi

    if [ -d "${PLUGINS_DIR}" ]; then
        echo "Updating ${PLUGINS_DIR}"
        cd "${PLUGINS_DIR}"
        git pull --all --prune
        echo;
    else
        echo "Creating ${PLUGINS_DIR}"
        cd "${MAIN_DIR}"
        git clone https://github.com/psi-im/plugins.git
        echo;
    fi

    if [ -d "${PSIMEDIA_DIR}" ]; then
        echo "Updating ${PSIMEDIA_DIR}"
        cd "${PSIMEDIA_DIR}"
        git pull --all --prune
        echo;
    else
        echo "Creating ${PSIMEDIA_DIR}"
        cd "${MAIN_DIR}"
        git clone https://github.com/psi-im/psimedia.git
        echo;
    fi

    # beginning of magical hack
    cd "${CUR_DIR}"
    rm -fr tmp
    mkdir tmp
    cd tmp/

    mkdir src
    mkdir src/plugins
    mkdir psimedia
    cp -a "${PLUGINS_DIR}"/* "src/plugins/"
    cp -a "${PSIMEDIA_DIR}"/psiplugin "psimedia/"

    cd "${PSI_DIR}/src"
    python ../admin/update_options_ts.py ../options/default.xml > \
        "${CUR_DIR}/tmp/option_translations.cpp"
    # ending of magical hack

    cd "${CUR_DIR}"
    rm translations.pro

    echo "HEADERS = \\" >> translations.pro
    find "${PSI_DIR}/iris" "${PSI_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.h" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done

    echo "SOURCES = \\" >> translations.pro
    find "${PSI_DIR}/iris" "${PSI_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.cpp" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.cpp" >> translations.pro

    echo "FORMS = \\" >> translations.pro
    find "${PSI_DIR}/iris" "${PSI_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.ui" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.ui" >> translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo translations/*.ts >> translations.pro

    lupdate -verbose ./translations.pro

    cp "${PSI_DIR}"/*.desktop "${CUR_DIR}/desktop-file/"

    git status

;;
"tr_fu")
    # Fast update of localization files.

    git status

    lupdate -verbose ./translations.pro

    cp "${PSI_DIR}"/*.desktop "${CUR_DIR}/desktop-file/"

    git status

;;
"tr_cl")
    # Cleaning update of localization files.

    git status

    lupdate -verbose -no-obsolete ./translations.pro

    cp "${PSI_DIR}"/*.desktop "${CUR_DIR}/desktop-file/"

    git status

;;
"tr_sync")
    # Syncing of Guthub repos.

    "${0}" tr
    "${0}" tr_up

    if [ "$(git status | grep 'translations/' | wc -l)" -gt 0 ]; then
        "${0}" cm
    fi
    echo ;
;;
"desktop_up")
    # Update main .desktop file
    GENERICNAME_FULL_DATA=$(grep -r "GenericName\[" "${CUR_DIR}/desktop-file/" | grep -v '/psi.desktop:' | grep -v '/psi_en.desktop:')
    GENERICNAME_FILTERED_DATA=$(echo "${GENERICNAME_FULL_DATA}" | sed -ne 's|^.*/psi_.*.desktop:\(.*\)$|\1|p')
    GENERICNAME_SORTED_DATA=$(echo "${GENERICNAME_FILTERED_DATA}" | sort -uV)

    COMMENT_FULL_DATA=$(grep -r "Comment\[" "${CUR_DIR}/desktop-file/" | grep -v '/psi.desktop:' | grep -v '/psi_en.desktop:')
    COMMENT_FILTERED_DATA=$(echo "${COMMENT_FULL_DATA}" | sed -ne 's|^.*/psi_.*.desktop:\(.*\)$|\1|p')
    COMMENT_SORTED_DATA=$(echo "${COMMENT_FILTERED_DATA}" | sort -uV)

    DESKTOP_FILE="${CUR_DIR}/desktop-file/psi.desktop"
    grep -v "GenericName\[" "${DESKTOP_FILE}" > "${DESKTOP_FILE}.tmp"
    mv -f "${DESKTOP_FILE}.tmp" "${DESKTOP_FILE}"
    grep -v "Comment\[" "${DESKTOP_FILE}" > "${DESKTOP_FILE}.tmp"
    mv -f "${DESKTOP_FILE}.tmp" "${DESKTOP_FILE}"
    echo "${GENERICNAME_SORTED_DATA}" >> "${DESKTOP_FILE}"
    echo "${COMMENT_SORTED_DATA}" >> "${DESKTOP_FILE}"

    # Update .desktop file for English localization
    cp -f "${CUR_DIR}/desktop-file/psi.desktop" \
          "${CUR_DIR}/desktop-file/psi_en.desktop"
;;
*)
    # Help.

    echo "Usage:"
    echo "  up cm push make install tarball"
    echo "  tr tr_up tr_fu tr_cl tr_co tr_sync desktop_up"
    echo ;
    echo "Examples:"
    echo "  ./update-translations.sh tr"
    echo "  ./update-translations.sh tr_up"
    echo "  ./update-translations.sh cm"
    echo "  ./update-translations.sh push"
    echo "  or"
    echo "  ./update-translations.sh tr_sync"
    echo "  ./update-translations.sh push"

;;
esac

exit 0
