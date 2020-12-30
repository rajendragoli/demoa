public class NodeJsV1 {
/*index.js

#!/usr/bin/env node
const sfCreatePackage = require('./sfCreatePackage');

var cli = require('cli');

cli.setApp('sf-create-package');

cli.parse({
    baseBranch:             [ 'b', 'Git base branch', 'string', 'develop' ],
    featureBranch:          [ 'f', 'Git feature branch', 'string', false ],
    packageFile:            [ 'p', 'Absolute path to the package.zip file that will be created', 'path', false ],
    testClassesFile:        [ 't', 'Absolute path to a file that would contain comma-separated list of test class names', 'string', false ],
    packageVersion:         [ 'v', 'Package version', 'string', '47.0' ],
    excludeProfiles:        [ 'excludeProfiles', 'Exclude Profiles', 'boolean', false ],
    excludePermissionSets:  [ 'excludePermissionSets', 'Exclude PermissionSets', 'boolean', false ]
});

cli.debug('Base branch ' + cli.options.baseBranch);
cli.debug('Feature branch ' + cli.options.featureBranch);
cli.debug('Package file ' + cli.options.packageFile);
cli.debug('Test Classes Name file ' + cli.options.testClassesFile);
cli.debug('Package version ' + cli.options.packageVersion);
cli.debug('Exclude Profiles ' + cli.options.excludeProfiles);
cli.debug('Exclude PermissionSets ' + cli.options.excludePermissionSets);

if (!cli.options.featureBranch) {
    cli.getUsage();
    cli.error('Git feature branch must be provided');
    cli.exit();
}

if (!cli.options.packageFile) {
    cli.getUsage();
    cli.error('package.zip file must be provided');
    cli.exit();
}
    
sfCreatePackage.init(cli.options.baseBranch, cli.options.featureBranch, cli.options.packageFile, cli.options.testClassesFile, cli.options.packageVersion, cli.options.excludeProfiles, cli.options.excludePermissionSets);

*/    
/* sf-create-package
    require('fs-posix');
var fs = require('fs-extra');
var glob = require('glob');
var cli = require('cli');
var tempDir = require('temp-dir');
var uuidv1 = require('uuid/v1');
var normalizePath = require('normalize-path');
//require('../package-xml');
var zipFolder = require('zip-folder');
var testClassesList = new Set();
var testClassesFilePath;

var callbackFunction;

function initWithCallback(baseBranch, featureBranch, packageFile, testClassesFile, packageVersion, excludeProfiles, excludePermissionSets, cbFunction) {
    callbackFunction = cbFunction;
    init(baseBranch, featureBranch, packageFile, testClassesFile, packageVersion, excludeProfiles, excludePermissionSets);
}

function init(baseBranch, featureBranch, packageFile, testClassesFile, packageVersion, excludeProfiles, excludePermissionSets) {
    const FILE_LIST = 'changedFiles';
    const DEPLOY_DIR = 'package';
    const DEFAULT_TEST_CLASSES_FILE = 'testClasses';
    
    var stagingDir = normalizePath(tempDir + '/sf-create-package/' + uuidv1());
    fs.ensureDirSync(stagingDir);
    cli.debug('Staging directory ' + stagingDir);

    if (testClassesFile) {
        testClassesFilePath = testClassesFile;
    }
    else {
        testClassesFilePath = normalizePath(stagingDir + '/' + DEFAULT_TEST_CLASSES_FILE);
    }
    
    var deployDirPath = stagingDir + '/' + DEPLOY_DIR;
    fs.ensureDirSync(deployDirPath);
    var changedFilesPath = stagingDir + '/' + FILE_LIST;
    
    // git diff --name-only --diff-filter=ACMRTUXB develop...release_branch > changedOrAddedFiles
    var gitDiffCommand = 'git diff --name-only --diff-filter=ACMRTUXB ' + baseBranch + '...' + featureBranch + ' > ' + changedFilesPath;
    cli.debug('Running command ' + gitDiffCommand + '...');
    cli.exec(gitDiffCommand, (lines) => {
        lines.forEach((value, index, array) => {
            if (value.trim().length > 0) {
                cli.error(value);
            }
        });
    
        if (fs.existsSync(changedFilesPath)) {
            cli.info('Generated list of metadata changes ' + changedFilesPath);
    
            copyFiles(normalizePath(process.cwd()), deployDirPath, changedFilesPath, excludeProfiles, excludePermissionSets, packageVersion, packageFile);
        }
        else {
            cli.error('Could not find file with metadata changes' + changedFilesPath);
            cli.exit();
        }
    });
}

function copyFiles(srcDir, deployDirPath, changedFilesPath, excludeProfiles, excludePermissionSets, packageVersion, packageFile) {

    var lineReader = require('readline').createInterface({
        input: require('fs').createReadStream(changedFilesPath)
    });
    
    fs.emptyDirSync(deployDirPath);
    
    lineReader.on('line', function (line) {
        
        // ignore package.xml
        if (line.includes('package.xml')) {
            return;
        }
        
        // ignore changes outside of src directory
        if (!line.startsWith('src')) {
            return;
        }
    
        // ignore Settings metadata
        if (line.startsWith('src/settings')) {
            return;
        }
    
        // ignore ProfilePasswordPolicies metadata
        if (line.startsWith('src/profilePasswordPolicies')) {
            return;
        }
    
        // ignore ProfileSessionSettings metadata
        if (line.startsWith('src/profileSessionSettings')) {
            return;
        }
    
        // ignore Reports metadata
        if (line.startsWith('src/reports')) {
            return;
        }
    
        // ignore dashboards metadata
        if (line.startsWith('src/dashboards')) {
            return;
        }
    
        // ignore appMenus metadata
        if (line.startsWith('src/appMenus')) {
            return;
        }
    
        if (line.startsWith('src/permissionsets') && excludePermissionSets) {
            return;
        }

        if (line.startsWith('src/profiles') && excludeProfiles) {
            return;
        }

        // determine file name and extension
        var lastSlashIndex = line.lastIndexOf('/');
        var fileRelativePath = line.slice(0, lastSlashIndex);
        var fileNameWithExtension = line.slice(lastSlashIndex + 1);
        var dotIndex = fileNameWithExtension.indexOf('.');
        var fileName = fileNameWithExtension.slice(0, dotIndex);
    
        // copy all relevant files for a particular metadata type
        var sourceCopyPath;
        if (line.includes('aura')) {
            var dirNames = fileRelativePath.split('/');
            var parentDirName = dirNames[dirNames.length - 1];
            sourceCopyPath = srcDir + '/' + fileRelativePath + '/' + parentDirName + '*.*';
        }
        else if (line.includes('customMetadata')) {
            sourceCopyPath = srcDir + '/' + fileRelativePath + '/' + fileNameWithExtension;
        }
        else if (line.includes('classes')) {
            sourceCopyPath = srcDir + '/' + fileRelativePath + '/' + fileName + '*(.cls|.cls-meta.xml|Test.cls|Test.cls-meta.xml|_Test.cls|_Test.cls-meta.xml|test.cls|test.cls-meta.xml)';
        }
        else {
            sourceCopyPath = srcDir + '/' + fileRelativePath + '/' + fileName + '*.*';
        }
        var destinationCopyPath = deployDirPath + '/' + fileRelativePath;
    
        // create destination directory
        fs.ensureDirSync(destinationCopyPath);
    
        glob(sourceCopyPath, function(err, files) {
            for (var i = 0; i < files.length; i++) {
                var lastSlashIndex_local = files[i].lastIndexOf('/');
                var fileNameWithExtension_local = files[i].slice(lastSlashIndex_local + 1);
                var destinationCopyPath_local = destinationCopyPath + '/' + fileNameWithExtension_local;
                fs.copySync(files[i], destinationCopyPath_local);

                // generate test class list here
                generateTestClassList(files[i]);

                cli.debug('Copied file ' + files[i] + ' to ' + destinationCopyPath_local);
            }
        });
            
    });
    
    lineReader.on('close', () => {
        createPackage(deployDirPath, packageVersion, packageFile);
    });

}

function createPackage(deployDirPath, packageVersion, packageFile) {
    //package-xml -D "./src" -v "45.0"
    var packageCommand = 'package-xml -D "' + deployDirPath + '" -v "' + packageVersion + '" -m';
    cli.exec(packageCommand, (lines) => {
        lines.forEach((value, index, array) => {
            if (value.trim().length > 0) {
                cli.debug(value);
            }
        });

        var packageXmlPath = deployDirPath + '/src/package.xml';
        if (fs.existsSync(packageXmlPath)) {
            cli.info('package.xml created successfully ' + packageXmlPath);

            zipPackage(deployDirPath, packageFile);
    
        }
        else {
            cli.error('Could not find package.xml' + packageXmlPath);
            cli.exit();
        }
    
    });
}

function zipPackage(deployDirPath, packageFile) {
    cli.info('Creating package zip file ' + packageFile);

    zipFolder(deployDirPath, packageFile, function(err) {
        if(err) {
            cli.error(err);
        } else {
            if (fs.existsSync(packageFile)) {
                cli.info('Package file created successfully ' + packageFile);

                // finally create comma-separated list of test classes
                exportTestClassList();
            }
            else {
                cli.error('Could not find package file ' + packageFile);
            }
        }
    });
}

function generateTestClassList(filePath) {
    if (filePath.includes('src/classes')) {
        if (filePath.includes('Test') || filePath.includes('test')) {
            var lastSlashIndex = filePath.lastIndexOf('/');
            var fileNameWithExtension = filePath.slice(lastSlashIndex + 1);
            var dotIndex = fileNameWithExtension.indexOf('.');
            var testClassName = fileNameWithExtension.slice(0, dotIndex);
            testClassesList.add(testClassName);
            cli.debug('Discovered test class ' + testClassName);
        }
    }
}

function exportTestClassList() {
    var testClassArray = Array.from(testClassesList);
    var testClassListString = testClassArray.join(',');
    cli.debug('Generated list of test class names ' + testClassListString);
    fs.writeFile(testClassesFilePath, testClassListString, (err) => {
        if (err) cli.error(err);
        cli.info('Test class list available here ' + testClassesFilePath);

        // finally call the callback function if one was provided
        if (callbackFunction) {
            callbackFunction();
        }
    });
}

module.exports = { initWithCallback, init, copyFiles, createPackage, zipPackage, generateTestClassList, exportTestClassList };




*/    
    
 /* sfCreatePackage.spec.js start
    const sfCreatePackage = require('./sfCreatePackage');

describe('sfCreatePackage', () => {
    it('should contain a initWithCallback method', () => {
        expect(sfCreatePackage).toHaveProperty('initWithCallback');
    });
    it('should contain a init method', () => {
        expect(sfCreatePackage).toHaveProperty('init');
    });
    it('should contain a copyFiles method', () => {
        expect(sfCreatePackage).toHaveProperty('copyFiles');
    });
    it('should contain a createPackage method', () => {
        expect(sfCreatePackage).toHaveProperty('createPackage');
    });
    it('should contain a zipPackage method', () => {
        expect(sfCreatePackage).toHaveProperty('zipPackage');
    });
    it('should contain a generateTestClassList method', () => {
        expect(sfCreatePackage).toHaveProperty('generateTestClassList');
    });
    it('should contain a exportTestClassList method', () => {
        expect(sfCreatePackage).toHaveProperty('exportTestClassList');
    });
});

 */   //sfCreatePackage.spec.js End
    
/*

const sfCreatePackage = require('./sfCreatePackage');

describe('sfCreatePackage', () => {
    it('should contain a initWithCallback method', () => {
        expect(sfCreatePackage).toHaveProperty('initWithCallback');
    });
    it('should contain a init method', () => {
        expect(sfCreatePackage).toHaveProperty('init');
    });
    it('should contain a copyFiles method', () => {
        expect(sfCreatePackage).toHaveProperty('copyFiles');
    });
    it('should contain a createPackage method', () => {
        expect(sfCreatePackage).toHaveProperty('createPackage');
    });
    it('should contain a zipPackage method', () => {
        expect(sfCreatePackage).toHaveProperty('zipPackage');
    });
    it('should contain a generateTestClassList method', () => {
        expect(sfCreatePackage).toHaveProperty('generateTestClassList');
    });
    it('should contain a exportTestClassList method', () => {
        expect(sfCreatePackage).toHaveProperty('exportTestClassList');
    });
});


*/ 
    

/* sfdc-create-deploy


require('fs-posix');
var fs = require('fs-extra');
var cli = require('cli');
var tempDir = require('temp-dir');
var uuidv1 = require('uuid/v1');
var normalizePath = require('normalize-path');
var timestamp = require('time-stamp');
var testClassesFilePath;

const sfCreatePackage = require('../sf-create-package/sfCreatePackage');

var packageFile;
var username;
var validationOnly;
var cicdMode;

function init(){
    const TEST_CLASSES_FILE = 'testClasses';
    
    cli.setApp('sf-create-package-deploy');
    
    cli.parse({
        baseBranch:             [ 'b', 'Git base branch', 'string', 'develop' ],
        featureBranch:          [ 'f', 'Git feature branch', 'string', false ],
        packageFile:            [ 'p', 'Absolute path to the package.zip file that will be created', 'path', false ],
        username:               [ 'u', 'pre-authenticated username, e.g, osman_mazhar@carmax.com.devcrm20', 'string', false ],
        validationOnly:         [ 'validateOnly', 'perform validation only', 'boolean', false ],
        packageVersion:         [ 'v', 'Package version', 'string', '47.0' ],
        cicdMode:               [ 'cicd', 'run in CI/CD mode by waiting until deployment is done, and output results in JSON format', 'boolean', false ],
        excludeProfiles:        [ 'excludeProfiles', 'Exclude Profiles', 'boolean', false ],
        excludePermissionSets:  [ 'excludePermissionSets', 'Exclude PermissionSets', 'boolean', false ]
    });
    
    cli.debug('Base branch ' + cli.options.baseBranch);
    cli.debug('Feature branch ' + cli.options.featureBranch);
    cli.debug('Package file ' + cli.options.packageFile);
    cli.debug('Username ' + cli.options.username);
    cli.debug('Validation Only ' + cli.options.validationOnly);
    cli.debug('Package version ' + cli.options.packageVersion);
    cli.debug('CI/CD Mode ' + cli.options.cicdMode);
    cli.debug('Exclude Profiles ' + cli.options.excludeProfiles);
    cli.debug('Exclude PermissionSets ' + cli.options.excludePermissionSets);
    
    if (!cli.options.featureBranch) {
        cli.getUsage();
        cli.error('Git feature branch must be provided');
        cli.exit();
    }
    
    if (!cli.options.username) {
        cli.getUsage();
        cli.error('username file must be provided');
        cli.exit();
    }

    username = cli.options.username;
    validationOnly = cli.options.validationOnly;
    cicdMode = cli.options.cicdMode;

    if (cli.options.packageFile) {
        packageFile = cli.options.packageFile;
    }
    else {
        packageFile = getNormalizedBranchName(cli.options.featureBranch) + '_' + getFormattedDate() + '__package.zip';
    }
    
    var stagingDir = normalizePath(tempDir + '/sf-create-package-deploy/' + uuidv1());
    fs.ensureDirSync(stagingDir);
    cli.debug('Staging directory ' + stagingDir);

    testClassesFilePath = normalizePath(stagingDir + '/' + TEST_CLASSES_FILE);

    // create package
    sfCreatePackage.initWithCallback(cli.options.baseBranch, cli.options.featureBranch, packageFile, testClassesFilePath, cli.options.packageVersion, cli.options.excludeProfiles, cli.options.excludePermissionSets, deployPackage);

}

function deployPackage() {
    // read test class list into string
    var testClassListString = fs.readFileSync(testClassesFilePath);
    var testingFlag = 'NoTestRun';
    var testClassFlagAndList = '';
    if (testClassListString.length > 0) {
        testingFlag = 'RunSpecifiedTests';
        testClassFlagAndList = ' -r ' + testClassListString;
    }
    var deployPackageCommand = 'sfdx force:mdapi:deploy -f ' + packageFile + ' -l ' + testingFlag + testClassFlagAndList + ' -u ' + username;

    if (validationOnly) {
        deployPackageCommand += ' -c';
    }

    if (cicdMode) {
        deployPackageCommand += ' -w -1 --json';
    }

    cli.debug('Running command ' + deployPackageCommand + '...');
    cli.exec(
        deployPackageCommand, 
        (lines) => {
            lines.forEach((value, index, array) => {
                if (value.trim().length > 0) {
                    cli.debug(value);
                }
            });
            if (cicdMode && lines && lines.length > 0) {
                processDeployResult(lines.join(''));
            }
        },
        (err, stdout) => {
            cli.error(err);
            cli.debug(stdout);

            if (cicdMode) {
                if (err) {
                    processDeployResult(new String(err));
                }
                if (stdout) {
                    processDeployResult(stdout);
                }
            }
        }
    );
}

function getNormalizedBranchName(branchName) {
    return branchName.replace(/\//g, '_');
}

function getFormattedDate() {
    return timestamp('YYYYMMDD');
}

function processDeployResult(rawOutput) {
    if (rawOutput.includes('"status": "Succeeded"')) {
        cli.info("Package successful. Exiting with code 0");
        cli.exit(0);
    }

    if (rawOutput.includes('"status": "Failed"')) {
        cli.error("Package failed. Exiting with code 1");
        cli.exit(1);
    }
}

module.exports = { init, deployPackage, getNormalizedBranchName, getFormattedDate, processDeployResult };



*/
/*
const sfCreatePackageDeploy = require('./sfCreatePackageDeploy');

describe('sfCreatePackageDeploy', () => {
    it('should contain a init method', () => {
        expect(sfCreatePackageDeploy).toHaveProperty('init');
    });
    it('should contain a deployPackage method', () => {
        expect(sfCreatePackageDeploy).toHaveProperty('deployPackage');
    });
    it('should contain a getNormalizedBranchName method', () => {
        expect(sfCreatePackageDeploy).toHaveProperty('getNormalizedBranchName');
    });
    it('should contain a getFormattedDate method', () => {
        expect(sfCreatePackageDeploy).toHaveProperty('getFormattedDate');
    });
    it('should contain a processDeployResult method', () => {
        expect(sfCreatePackageDeploy).toHaveProperty('processDeployResult');
    });
});
 
*/     
}