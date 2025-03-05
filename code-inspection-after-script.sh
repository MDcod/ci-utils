#!/bin/bash

# HTML-шаблон
HTML_TEMPLATE=$(cat <<'EOF'
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code Inspection Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #0d1117;
            color: #c9d1d9;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }

        .container {
            display: flex;
            width: 95%;
            height: 95%;
            gap: 10px;
        }

        .left-panel {
            display: flex;
            flex-direction: column;
            width: 400px;
            /* Фиксированная ширина */
            min-width: 400px;
            /* Минимальная ширина */
            max-width: 400px;
            /* Максимальная ширина */
            gap: 10px;
            height: 100%;
            /* Занимает всю доступную высоту */
        }

        .projects,
        .issues {
            background-color: #161b22;
            padding: 15px;
            border-radius: 6px;
            border: 1px solid #30363d;
        }

        .projects {
            max-height: 50vh;
            /* Максимальная высота — 50% от высоты экрана */
            overflow-y: auto;
            /* Вертикальный скролл, если контента больше */
            flex-shrink: 0;
            /* Запрещаем сжатие */
        }

        .issues {
            flex-grow: 1;
            /* Занимает оставшееся пространство в левой панели */
            overflow-y: auto;
            /* Вертикальный скролл, если контента больше */
            flex-shrink: 0;
            /* Запрещаем сжатие */
            max-height: calc(100vh - 50vh + 3px);
            /* Ограничение по высоте (оставшееся пространство) */
        }

        .files {
            flex-grow: 1;
            /* Занимает всё оставшееся пространство справа */
            background-color: #161b22;
            padding: 15px;
            border-radius: 6px;
            border: 1px solid #30363d;
            overflow-y: auto; /* Вертикальный скролл, если контента больше */
            overflow-x: hidden; /* Убираем горизонтальный скролл */
        }

        h2 {
            margin-top: 0;
        }

        ul {
            list-style-type: none;
            padding: 0;
        }

        li {
            padding: 8px;
            margin: 5px 0;
            border-radius: 4px;
            cursor: pointer;
        }

        li:hover {
            background-color: #21262d;
        }

        .project-item,
        .issue-item {
            background-color: #30363d;
            color: white;
                    
            overflow: hidden; /* Обрезаем текст */
            white-space: nowrap; /* Запрещаем перенос */
            text-overflow: ellipsis; /* Многоточие для обрезанного текста */
        }

        .project-item.selected,
        .issue-item.selected {
            background-color: #1f71eb89 !important;
            /* Синий цвет для выделения */
            color: white;
        }

        .project-item.error,
        .file-item.error {
            background-color: #f85149;
            color: white;
        }

        /* Убираем hover-эффект для элементов Files */
        .file-item:hover {
            background-color: #30363d; /* Оставляем тот же цвет, что и без наведения */
            color: #c9d1d9; /* Оставляем тот же цвет текста */
        }

        /* Оставляем hover-эффект для проектов и Issue */
        .project-item:hover, .issue-item:hover {
            background-color: #21262d; /* Эффект наведения для проектов и Issue */
        }


        /* Убедимся, что selected переопределяет error */
        .project-item.selected.error,
        .issue-item.selected.error {
            background-color: #1f71eb89 !important;
            /* Синий цвет для выделения */
            color: white;
        }

        /* Стили для элементов файлов */
        .file-item {
            background-color: #30363d;
            color: #c9d1d9;
            padding: 10px;
            margin: 5px 0;
            border-radius: 4px;
            cursor: pointer;
        }

        .file-item.error {
            background-color: #f85149;
            color: white;
        }


        .file-item .details {
            display: none;
            /* Скрываем детали по умолчанию */
            margin-top: 10px;
            padding: 10px;
            background-color: #21262d;
            border-radius: 4px;
            cursor: default; /* Обычный курсор (стрелка) */

            white-space: normal;
        }

        .file-item .details .type-id {
            color: #c9d1d9;
            font-size: 0.9em;
        }

        .file-item .details .description {
            color: #8b949e;
            font-size: 0.9em;
            margin-top: 5px;
        }

        /* Стили для иконки знака вопроса в кругу */
        .file-item .details .wiki-link {
            display: inline-flex;
            align-items: center;
            margin-left: 10px;
            text-decoration: none;
        }

        .file-item .details .wiki-link svg {
            width: 16px;
            height: 16px;
            fill: #58a6ff;
            /* Цвет иконки */
            background-color: #30363d;
            border-radius: 50%;
            /* Круглая форма */
            padding: 4px;
        }

        .file-item .details .wiki-link:hover svg {
            fill: #1f6feb;
            /* Цвет иконки при наведении */
        }

        /* Стили для ссылки на строку */
        .file-item .details .line-link {
            color: #58a6ff;
            text-decoration: none;
        }

        .file-item .details .line-link:hover {
            text-decoration: underline;
        }

        /* Стили для группировки ошибок по TypeId */
        .file-item .details .type-group {
            margin-bottom: 15px;
            padding: 10px;
            background-color: #21262d;
            border-radius: 4px;
        }

        .file-item .details .type-group .issue {
            margin-left: 20px;
            margin-top: 5px;
        }

        .file-item .details .type-group .issue .line-link {
            color: #58a6ff;
            text-decoration: none;
        }

        .file-item .details .type-group .issue .line-link:hover {
            text-decoration: underline;
        }

        .file-item .details .type-group .issue .message {
            color: #8b949e;
            font-size: 0.9em;
        }


        /* Стили для заголовка файла */
        .file-item .file-path {
            font-weight: bold;
            display: flex;
            align-items: center;
            justify-content: space-between;
            
            
    overflow: hidden; /* Обрезаем текст */
    white-space: nowrap; /* Запрещаем перенос */
    text-overflow: ellipsis; /* Многоточие для обрезанного текста */
        }

        /* Стили для иконки стрелки */
        .file-item .file-path .toggle-icon {
            width: 16px;
            height: 16px;
            fill: #8b949e;
            /* Серый цвет иконки */
            transition: fill 0.2s;
        }

        .file-item:hover .file-path .toggle-icon {
            fill: #58a6ff;
            /* Синий цвет при наведении */
        }

        /* Стили для ошибок с уровнем ERROR */
        .file-item .details .type-group.error .type-header {
            color: #f85149;
            /* Красный цвет для TypeId */
        }

        /* Стили для ошибок с уровнем ERROR */
        .file-item .details .type-group.error .type-header-description {
            color: #f85149;
            /* Красный цвет для TypeId */
        }

        .file-item .details .type-group .type-header {
            font-weight: bold;
            color: #c9d1d9;
            margin-bottom: 2px;
        }

        .file-item .details .type-group .type-header-description {
            font-weight: normal;
            margin-bottom: 5px;
            font-size: 0.9em;
        }

        /* Стили для иконки вопроса в заголовке группы */
        .file-item .details .type-group .type-header .wiki-link {
            display: inline-flex;
            align-items: center;
            margin-left: 10px;
            text-decoration: none;
        }

        .file-item .details .type-group .type-header .wiki-link svg {
            width: 16px;
            height: 16px;
            fill: #8b949e;
            /* Серый цвет иконки */
            transition: fill 0.2s;
        }

        .file-item .details .type-group .type-header .wiki-link:hover svg {
            fill: #58a6ff;
            /* Синий цвет при наведении */
        }









        /* Стилизация скроллбаров для WebKit (Chrome, Safari, Edge) */
        ::-webkit-scrollbar {
            width: 10px;
            /* Ширина скроллбара */
        }

        ::-webkit-scrollbar-track {
            background: #161b22;
            /* Цвет трека (фона скроллбара) */
            border-radius: 5px;
            /* Закругление углов трека */
        }

        ::-webkit-scrollbar-thumb {
            background: #30363d;
            /* Цвет ползунка */
            border-radius: 5px;
            /* Закругление углов ползунка */
            border: 2px solid #161b22;
            /* Граница ползунка */
        }

        ::-webkit-scrollbar-thumb:hover {
            background: #238636;
            /* Цвет ползунка при наведении */
        }

        /* Стилизация скроллбаров для Firefox */
        * {
            scrollbar-width: thin;
            /* Тонкий скроллбар */
            scrollbar-color: #30363d #161b22;
            /* Цвет ползунка и трека */
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="left-panel">
            <div class="projects">
                <h2>Projects</h2>
                <ul id="project-list">
                    <li class="project-item" data-project="All">All</li>
                    <!-- Project items will be dynamically inserted here -->
                </ul>
            </div>
            <div class="issues">
                <h2>Issue Types</h2>
                <ul id="issue-list">
                    <li class="issue-item" data-issue="All">All</li>
                    <!-- Issue items will be dynamically inserted here -->
                </ul>
            </div>
        </div>
        <div class="files">
            <ul id="file-list">
                <!-- File items will be dynamically inserted here -->
            </ul>
        </div>
    </div>
    <script>
        const xmlData = `
        %XML-CODE-QUALITY-REPORT%
        `;

        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(xmlData.trimStart(), "application/xml");

        // Проверка на ошибки парсинга
        const parserError = xmlDoc.querySelector("parsererror");
        if (parserError) {
            console.error("Ошибка при парсинге XML:", parserError.textContent);
        } else {
            console.log("XML успешно распарсен:", xmlDoc);
        }

        // Используем XPath для поиска элементов с учётом пространства имён
        const nsResolver = (prefix) => {
            const ns = {
                '': 'http://www.w3.org/XML/1998/namespace', // Пространство имён по умолчанию
            };
            return ns[prefix] || null;
        };

        const projects = xmlDoc.evaluate("//Project", xmlDoc, nsResolver, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        const issueTypes = xmlDoc.evaluate("//IssueType", xmlDoc, nsResolver, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);

        const projectList = document.getElementById("project-list");
        const issueList = document.getElementById("issue-list");
        const fileList = document.getElementById("file-list");

        let selectedProject = "All";
        let selectedIssueType = "All";

        function renderProjects() {
            projectList.innerHTML = `<li class="project-item ${selectedProject === "All" ? 'selected' : ''}" data-project="All">All</li>`;
            const projectItems = [];

            // Сначала добавляем проекты с ошибками
            for (let i = 0; i < projects.snapshotLength; i++) {
                const project = projects.snapshotItem(i);
                const projectName = project.getAttribute("Name");
                const hasError = Array.from(project.querySelectorAll("Issue")).some(issue => issue.getAttribute("Severity") === "ERROR");
                if (hasError) {
                    const projectItem = document.createElement("li");
                    projectItem.className = `project-item ${hasError ? 'error' : ''} ${selectedProject === projectName ? 'selected' : ''}`;
                    projectItem.textContent = projectName;
                    projectItem.setAttribute("data-project", projectName);
                    projectItems.unshift(projectItem); // Добавляем в начало списка
                }
            }

            // Затем добавляем остальные проекты
            for (let i = 0; i < projects.snapshotLength; i++) {
                const project = projects.snapshotItem(i);
                const projectName = project.getAttribute("Name");
                const hasError = Array.from(project.querySelectorAll("Issue")).some(issue => issue.getAttribute("Severity") === "ERROR");
                if (!hasError) {
                    const projectItem = document.createElement("li");
                    projectItem.className = `project-item ${selectedProject === projectName ? 'selected' : ''}`;
                    projectItem.textContent = projectName;
                    projectItem.setAttribute("data-project", projectName);
                    projectItems.push(projectItem); // Добавляем в конец списка
                }
            }

            // Добавляем все элементы в DOM
            projectItems.forEach(item => projectList.appendChild(item));
        }

        function renderIssueTypes() {
            issueList.innerHTML = `<li class="issue-item ${selectedIssueType === "All" ? 'selected' : ''}" data-issue="All">All</li>`;
            const issueTypesInProject = new Set(); // Используем Set для хранения уникальных типов Issue

            // Если выбран конкретный проект, собираем типы Issue из этого проекта
            if (selectedProject !== "All") {
                const selectedProjectElement = Array.from({ length: projects.snapshotLength }, (_, i) => projects.snapshotItem(i))
                    .find(project => project.getAttribute("Name") === selectedProject);

                if (selectedProjectElement) {
                    const issues = Array.from(selectedProjectElement.querySelectorAll("Issue"));
                    issues.forEach(issue => {
                        issueTypesInProject.add(issue.getAttribute("TypeId"));
                    });
                }
            }

            // Отображаем типы Issue
            for (let i = 0; i < issueTypes.snapshotLength; i++) {
                const issueType = issueTypes.snapshotItem(i);
                const issueId = issueType.getAttribute("Id");

                // Если выбран проект "All" или тип Issue есть в выбранном проекте, отображаем его
                if (selectedProject === "All" || issueTypesInProject.has(issueId)) {
                    const issueItem = document.createElement("li");
                    issueItem.className = `issue-item ${selectedIssueType === issueId ? 'selected' : ''}`;
                    issueItem.textContent = issueId;
                    issueItem.setAttribute("data-issue", issueId);
                    issueList.appendChild(issueItem);
                }
            }
        }

        function renderFiles() {
            fileList.innerHTML = '';
            const selectedProjectElement = selectedProject === "All"
                ? Array.from({ length: projects.snapshotLength }, (_, i) => projects.snapshotItem(i))
                : Array.from({ length: projects.snapshotLength }, (_, i) => projects.snapshotItem(i)).filter(project => project.getAttribute("Name") === selectedProject);

            // Группируем ошибки по файлам и TypeId
            const fileMap = new Map();

            selectedProjectElement.forEach(project => {
                const issues = Array.from(project.querySelectorAll("Issue")).filter(issue => selectedIssueType === "All" || issue.getAttribute("TypeId") === selectedIssueType);
                issues.forEach(issue => {
                    const file = issue.getAttribute("File");
                    const message = issue.getAttribute("Message");
                    const severity = issue.getAttribute("Severity") || issueTypes.snapshotItem(0).getAttribute("Severity");
                    const typeId = issue.getAttribute("TypeId");
                    const lineNumber = issue.getAttribute("Line");
                    const issueTypesArray = Array.from({ length: issueTypes.snapshotLength }, (_, i) => issueTypes.snapshotItem(i));
                    const issueType = issueTypesArray.find(type => type.getAttribute("Id") === typeId);
                    const description = issueType ? issueType.getAttribute("Description") : "No description available";
                    const wikiUrl = issueType ? issueType.getAttribute("WikiUrl") : "#";

                    if (!fileMap.has(file)) {
                        fileMap.set(file, new Map());
                    }
                    const typeMap = fileMap.get(file);
                    if (!typeMap.has(typeId)) {
                        typeMap.set(typeId, { description, wikiUrl, issues: [] });
                    }
                    typeMap.get(typeId).issues.push({ lineNumber, message, severity });
                });
            });

            // Создаём элементы для каждого файла
            const fileItems = [];
            fileMap.forEach((typeMap, file) => {
                const fileItem = document.createElement("li");
                fileItem.className = `file-item ${Array.from(typeMap.values()).some(group => group.issues.some(issue => issue.severity === 'ERROR')) ? 'error' : ''}`;

                // Заголовок файла
                const filePath = document.createElement("div");
                filePath.className = "file-path";
                filePath.textContent = file;

                // Иконка для сворачивания/разворачивания
                const toggleIcon = document.createElement("div");
                toggleIcon.className = "toggle-icon";
                toggleIcon.innerHTML = `
            <svg viewBox="0 0 24 24" width="16" height="16">
                <path d="M7 10l5 5 5-5z"/>
            </svg>
        `;
                filePath.appendChild(toggleIcon);

                fileItem.appendChild(filePath);

                // Детали (скрыты по умолчанию)
                const details = document.createElement("div");
                details.className = "details";
                details.style.display = "none"; // По умолчанию скрыты

                // Сортируем группы: сначала ошибки с уровнем ERROR
                const sortedGroups = Array.from(typeMap.entries()).sort(([typeIdA, groupA], [typeIdB, groupB]) => {
                    const aHasError = groupA.issues.some(issue => issue.severity === 'ERROR');
                    const bHasError = groupB.issues.some(issue => issue.severity === 'ERROR');
                    if (aHasError && !bHasError) return -1;
                    if (!aHasError && bHasError) return 1;
                    return 0;
                });

                // Добавляем группы ошибок по TypeId
                sortedGroups.forEach(([typeId, group]) => {
                    const typeGroup = document.createElement("div");
                    typeGroup.className = `type-group ${group.issues.some(issue => issue.severity === 'ERROR') ? 'error' : ''}`;

                    // Заголовок группы: TypeId и Description
                    const typeHeader = document.createElement("div");
                    typeHeader.className = "type-header";
                    typeHeader.textContent = `${typeId}`;

                    const descriptionSpan = document.createElement("div");
                    descriptionSpan.className = "type-header-description";
                    descriptionSpan.textContent = `${group.description}`;

                    // SVG иконка знака вопроса в кругу
                    const wikiLink = document.createElement("a");
                    wikiLink.className = "wiki-link";
                    wikiLink.href = group.wikiUrl;
                    wikiLink.target = "_blank"; // Открывать в новой вкладке
                    wikiLink.innerHTML = `
                <svg viewBox="0 0 24 24" width="16" height="16">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 17h-2v-2h2v2zm2.07-7.75l-.9.92C13.45 12.9 13 13.5 13 15h-2v-.5c0-1.1.45-2.1 1.17-2.83l1.24-1.26c.37-.36.59-.86.59-1.41 0-1.1-.9-2-2-2s-2 .9-2 2H8c0-2.21 1.79-4 4-4s4 1.79 4 4c0 .88-.36 1.68-.93 2.25z"/>
                </svg>
            `;
                    typeHeader.appendChild(wikiLink);
                    typeGroup.appendChild(typeHeader);
                    typeGroup.appendChild(descriptionSpan);

                    // Добавляем ошибки для этого TypeId
                    group.issues.forEach(issue => {
                        const issueDiv = document.createElement("div");
                        issueDiv.className = "issue";

                        // Строка: Line и Message
                        const lineLink = document.createElement("a");
                        lineLink.className = "line-link";
                        lineLink.href = `$CI_PROJECT_URL/-/blob/$CI_COMMIT_BRANCH/${file}#L${issue.lineNumber}`;
                        lineLink.target = "_blank"; // Открывать в новой вкладке
                        lineLink.textContent = `Line: (${issue.lineNumber})`;
                        issueDiv.appendChild(lineLink);

                        const messageSpan = document.createElement("span");
                        messageSpan.className = "message";
                        messageSpan.textContent = ` — ${issue.message}`;
                        issueDiv.appendChild(messageSpan);

                        typeGroup.appendChild(issueDiv);
                    });

                    details.appendChild(typeGroup);
                });

                fileItem.appendChild(details);

                // Обработчик клика для раскрытия/скрытия деталей
                const toggleDetails = () => {
                    details.style.display = details.style.display === "block" ? "none" : "block";
                    toggleIcon.innerHTML = details.style.display === "block"
                        ? `<svg viewBox="0 0 24 24" width="16" height="16"><path d="M7 14l5-5 5 5z"/></svg>`
                        : `<svg viewBox="0 0 24 24" width="16" height="16"><path d="M7 10l5 5 5-5z"/></svg>`;
                };

                // Клик на путь файла
                filePath.addEventListener("click", (e) => {
                    e.stopPropagation(); // Останавливаем всплытие, чтобы не сработал клик на fileItem
                    toggleDetails();
                });

                // Клик на весь элемент fileItem (но не на details)
                fileItem.addEventListener("click", (e) => {
                    if (!e.target.closest(".details")) { // Игнорируем клики внутри details
                        toggleDetails();
                    }
                });

                fileItems.push(fileItem);
            });

            // Сортируем файлы: сначала с ошибками, затем остальные
            fileItems.sort((a, b) => {
                const aHasError = a.classList.contains("error");
                const bHasError = b.classList.contains("error");
                if (aHasError && !bHasError) return -1;
                if (!aHasError && bHasError) return 1;
                return 0;
            });

            // Добавляем все элементы в DOM
            fileItems.forEach(item => fileList.appendChild(item));
        }

        projectList.addEventListener("click", (e) => {
            if (e.target.classList.contains("project-item")) {
                selectedProject = e.target.getAttribute("data-project");
                selectedIssueType = "All"; // Сбрасываем выбор типа Issue при смене проекта
                renderProjects(); // Перерисовываем проекты
                renderIssueTypes(); // Перерисовываем типы Issue
                renderFiles(); // Перерисовываем файлы
            }
        });

        issueList.addEventListener("click", (e) => {
            if (e.target.classList.contains("issue-item")) {
                selectedIssueType = e.target.getAttribute("data-issue");
                renderIssueTypes(); // Перерисовываем типы Issue, чтобы обновить выделение
                renderFiles(); // Обновляем список файлов
            }
        });

        renderProjects();
        renderIssueTypes();
        const issueTypesArray = Array.from({ length: issueTypes.snapshotLength }, (_, i) => issueTypes.snapshotItem(i));
        console.log(issueTypesArray.find(type => type.getAttribute("Id") === "NotAccessedField.Local"))
        console.log(issueTypesArray)
        console.log(issueTypes)
        renderFiles();
    </script>
</body>

</html>
EOF
)

CODE_INSPECTION_XML="$CI_PROJECT_DIR/inspectcode/code-inspection.xml"
HTML_FILE="$CI_PROJECT_DIR/inspectcode/code-inspection.html"

issues_count=$(grep -oF "<Issue TypeId=" "$CODE_INSPECTION_XML" | wc -l)

# Временный файл для хранения экранированного XML
TEMP_FILE=$(mktemp)

# Чтение XML-файла и экранирование символов
sed 's/\\/\\\\/g;' "$CODE_INSPECTION_XML" > "$TEMP_FILE"

# Генерация HTML-файла с подстановкой XML
printf "%s" "$HTML_TEMPLATE" | sed -e "/%XML-CODE-QUALITY-REPORT%/ {
    r $TEMP_FILE
    d
}" > "$HTML_FILE"

# Удаление временного файла
rm "$TEMP_FILE"

sed -i "s|\$CI_PROJECT_URL|$CI_PROJECT_URL|g" "$HTML_FILE"
sed -i "s|\$CI_COMMIT_BRANCH|$CI_COMMIT_BRANCH|g" "$HTML_FILE"

echo "Файл $HTML_FILE успешно создан!"

mkdir -p $CI_PROJECT_DIR/annotations
echo """{
        \"$(date +%s)\": [
            {
                \"external_link\": {
                    \"label\": \"Code inspection report ($issues_count Issues)\",
                    \"url\": \"$CI_SERVER_PROTOCOL://$CI_PROJECT_NAMESPACE.$CI_PAGES_DOMAIN/-/$CI_PROJECT_TITLE/-/jobs/$CI_JOB_ID/artifacts/inspectcode/code-inspection.html\"
                }
            }
        ]
    }""" > $CI_PROJECT_DIR/annotations/$(date +%s).json
