const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        "Specify static or dynamic linkage",
    ) orelse .dynamic;
    const upstream = b.dependency("rcl", .{});

    const rcutils_dep = b.dependency("rcutils", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    const libyaml_dep = b.dependency("libyaml", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    const rmw_dep = b.dependency("rmw", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    var yaml_param_parser = std.Build.Step.Compile.create(b, .{
        .root_module = .{
            .target = target,
            .optimize = optimize,
            .pic = if (linkage == .dynamic) true else null,
        },
        .name = "rcl_yaml_param_parser",
        .kind = .lib,
        .linkage = linkage,
    });

    const rosidl_dep = b.dependency("rosidl", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    const rcl_interfaces_dep = b.dependency("rcl_interfaces", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    const rcl_logging_dep = b.dependency("rcl_logging", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    yaml_param_parser.linkLibC();

    yaml_param_parser.addIncludePath(upstream.path("rcl_yaml_param_parser/include"));
    yaml_param_parser.installHeadersDirectory(
        upstream.path("rcl_yaml_param_parser/include"),
        "",
        .{},
    );

    yaml_param_parser.addCSourceFiles(.{
        .root = upstream.path("rcl_yaml_param_parser"),
        .files = &.{
            "src/add_to_arrays.c",
            "src/namespace.c",
            "src/node_params.c",
            "src/parse.c",
            "src/parser.c",
            "src/yaml_variant.c",
        },
        .flags = &.{
            "-fvisibility=hidden",
        },
    });
    yaml_param_parser.linkLibrary(rmw_dep.artifact("rmw"));

    yaml_param_parser.linkLibrary(libyaml_dep.artifact("yaml"));
    yaml_param_parser.linkLibrary(rcutils_dep.artifact("rcutils"));
    b.installArtifact(yaml_param_parser);

    var rcl = std.Build.Step.Compile.create(b, .{
        .root_module = .{
            .target = target,
            .optimize = optimize,
            .pic = if (linkage == .dynamic) true else null,
        },
        .name = "rcl",
        .kind = .lib,
        .linkage = linkage,
    });

    rcl.addIncludePath(b.dependency("ros2_tracing", .{}).namedWriteFiles(
        "tracetools",
    ).getDirectory());

    rcl.addIncludePath(upstream.path("rcl/include"));
    rcl.addIncludePath(upstream.path("rcl/src"));
    rcl.installHeadersDirectory(upstream.path("rcl/include"), "", .{});

    rcl.linkLibrary(rcutils_dep.artifact("rcutils"));
    rcl.linkLibrary(rmw_dep.artifact("rmw"));
    rcl.linkLibrary(rosidl_dep.artifact("rosidl_runtime_c"));
    rcl.linkLibrary(rosidl_dep.artifact("rosidl_dynamic_typesupport"));
    rcl.addIncludePath(rosidl_dep.namedWriteFiles("rosidl_typesupport_interface").getDirectory());

    rcl.linkLibrary(yaml_param_parser);
    rcl.linkLibrary(libyaml_dep.artifact("yaml"));
    rcl.linkLibrary(rcl_logging_dep.artifact("rcl_logging_interface"));

    // TODO rosidl should probably have a helper script for linking the correct things?
    // linkLibraryRecursive(rcl, rcl_interfaces_dep.artifact("type_description_interfaces__rosidl_generator_c"));
    // linkLibraryRecursive(rcl, rcl_interfaces_dep.artifact("type_description_interfaces__rosidl_typesupport_c"));
    // linkLibraryRecursive(rcl, rcl_interfaces_dep.artifact("rcl_interfaces__rosidl_generator_c"));
    // linkLibraryRecursive(rcl, rcl_interfaces_dep.artifact("rcl_interfaces__rosidl_typesupport_c"));
    rcl.linkLibrary(rcl_interfaces_dep.artifact("type_description_interfaces__rosidl_generator_c"));
    rcl.linkLibrary(rcl_interfaces_dep.artifact("type_description_interfaces__rosidl_typesupport_c"));
    rcl.linkLibrary(rcl_interfaces_dep.artifact("service_msgs__rosidl_generator_c"));
    rcl.linkLibrary(rcl_interfaces_dep.artifact("service_msgs__rosidl_typesupport_c"));
    rcl.linkLibrary(rcl_interfaces_dep.artifact("builtin_interfaces__rosidl_generator_c"));
    rcl.linkLibrary(rcl_interfaces_dep.artifact("builtin_interfaces__rosidl_typesupport_c"));
    rcl.linkLibrary(rcl_interfaces_dep.artifact("rcl_interfaces__rosidl_generator_c"));
    rcl.linkLibrary(rcl_interfaces_dep.artifact("rcl_interfaces__rosidl_typesupport_c"));

    rcl.addCSourceFiles(.{
        .root = upstream.path("rcl/src/rcl"),
        .files = &.{
            "arguments.c",
            "client.c",
            "common.c",
            "context.c",
            "discovery_options.c",
            "domain_id.c",
            "dynamic_message_type_support.c",
            "event.c",
            "expand_topic_name.c",
            "graph.c",
            "guard_condition.c",
            "init.c",
            "init_options.c",
            "lexer.c",
            "lexer_lookahead.c",
            "localhost.c",
            "logging.c",
            "logging_rosout.c",
            "log_level.c",
            "network_flow_endpoints.c",
            "node.c",
            "node_options.c",
            "node_resolve_name.c",
            "node_type_cache.c",
            "publisher.c",
            "remap.c",
            "rmw_implementation_identifier_check.c",
            "security.c",
            "service.c",
            "service_event_publisher.c",
            "subscription.c",
            "time.c",
            "timer.c",
            "type_description_conversions.c",
            "type_hash.c",
            "validate_enclave_name.c",
            "validate_topic_name.c",
            "wait.c",
        },
        .flags = &.{
            "-DROS_PACKAGE_NAME=\"rcl\"", // TODO this is used for logging in many packages, normally comes from ament, see if there's a way to automate this https://github.com/ros2/ament_cmake_ros/blob/jazzy/ament_cmake_ros/ament_cmake_ros-extras.cmake.in#L25
            "-fvisibility=hidden",
        },
    });
    b.installArtifact(rcl);
}
